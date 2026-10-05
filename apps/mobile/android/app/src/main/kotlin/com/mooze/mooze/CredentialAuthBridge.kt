package com.mooze.mooze

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicReference

/**
 * Native bridge for the device-credential fallback flow.
 *
 * Exists because the `local_auth` plugin always combines BIOMETRIC_STRONG with
 * DEVICE_CREDENTIAL in its `allowedAuthenticators` mask. That combination is
 * documented as unsupported on API 28-29 and breaks on Xiaomi / MIUI / HyperOS
 * devices where the fingerprint sensor is classified as Class 2 (WEAK).
 *
 * We instead request the documented-safe BIOMETRIC_WEAK | DEVICE_CREDENTIAL
 * mask and, if the AndroidX BiometricPrompt refuses to launch or errors out,
 * fall through to KeyguardManager.createConfirmDeviceCredentialIntent — the
 * lowest-level credential confirmation API and the one AndroidX itself uses
 * internally as the fallback path.
 *
 * The biometric-only flow stays on `local_auth` (which works correctly there).
 */
class CredentialAuthBridge(private val activity: FragmentActivity) :
    MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "CredentialAuthBridge"
        private const val CHANNEL = "com.mooze.auth/credential"
        private const val REQUEST_CONFIRM_CREDENTIAL = 0xA111
    }

    private val pendingResult = AtomicReference<MethodChannel.Result?>(null)
    private var biometricPrompt: BiometricPrompt? = null

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(this)
    }

    /** Forward Activity results from MainActivity for the keyguard fallback. */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != REQUEST_CONFIRM_CREDENTIAL) return false
        completeWith(resultCode == Activity.RESULT_OK)
        return true
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "authenticateWithCredential" -> authenticateWithCredential(call, result)
            "canAuthenticateWithCredential" -> result.success(canAuthenticate())
            else -> result.notImplemented()
        }
    }

    private fun canAuthenticate(): Boolean {
        val mask = BiometricManager.Authenticators.BIOMETRIC_WEAK or
            BiometricManager.Authenticators.DEVICE_CREDENTIAL
        val status = BiometricManager.from(activity).canAuthenticate(mask)
        if (status != BiometricManager.BIOMETRIC_SUCCESS) {
            // Treat keyguard-only devices as "can authenticate" since the
            // fallback intent does not require a biometric.
            val keyguard = activity.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            return keyguard.isDeviceSecure
        }
        return true
    }

    private fun authenticateWithCredential(call: MethodCall, result: MethodChannel.Result) {
        if (!pendingResult.compareAndSet(null, result)) {
            result.error("BUSY", "Authentication already in progress", null)
            return
        }

        val reason = call.argument<String>("reason").orEmpty()
        val title = call.argument<String>("title") ?: "Verify it's you"
        val subtitle = call.argument<String>("subtitle")

        val mask = BiometricManager.Authenticators.BIOMETRIC_WEAK or
            BiometricManager.Authenticators.DEVICE_CREDENTIAL

        when (val status = BiometricManager.from(activity).canAuthenticate(mask)) {
            BiometricManager.BIOMETRIC_SUCCESS -> {
                showBiometricPrompt(reason, title, subtitle, mask)
            }
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE,
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE,
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED,
            BiometricManager.BIOMETRIC_ERROR_UNSUPPORTED -> {
                Log.i(TAG, "Biometric mask unsupported (status=$status); falling back to keyguard")
                launchKeyguardFallback(title, subtitle ?: reason)
            }
            BiometricManager.BIOMETRIC_ERROR_SECURITY_UPDATE_REQUIRED -> {
                Log.i(TAG, "Security update required; falling back to keyguard")
                launchKeyguardFallback(title, subtitle ?: reason)
            }
            else -> {
                Log.w(TAG, "Unknown canAuthenticate status=$status; falling back to keyguard")
                launchKeyguardFallback(title, subtitle ?: reason)
            }
        }
    }

    private fun showBiometricPrompt(
        reason: String,
        title: String,
        subtitle: String?,
        authenticators: Int,
    ) {
        val executor = ContextCompat.getMainExecutor(activity)
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                completeWith(true)
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                Log.i(TAG, "BiometricPrompt error code=$errorCode msg=$errString")
                when (errorCode) {
                    BiometricPrompt.ERROR_USER_CANCELED,
                    BiometricPrompt.ERROR_NEGATIVE_BUTTON,
                    BiometricPrompt.ERROR_CANCELED -> completeWith(false)

                    BiometricPrompt.ERROR_NO_DEVICE_CREDENTIAL,
                    BiometricPrompt.ERROR_HW_UNAVAILABLE,
                    BiometricPrompt.ERROR_HW_NOT_PRESENT,
                    BiometricPrompt.ERROR_NO_BIOMETRICS -> {
                        // Xiaomi/MIUI failure mode — route directly to keyguard.
                        launchKeyguardFallback(title, subtitle ?: reason)
                    }

                    BiometricPrompt.ERROR_LOCKOUT,
                    BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> {
                        // Biometric locked out — keyguard PIN still works.
                        launchKeyguardFallback(title, subtitle ?: reason)
                    }

                    else -> completeError("BIOMETRIC_ERROR_$errorCode", errString.toString())
                }
            }

            override fun onAuthenticationFailed() {
                // Single attempt failed; user can retry inside the prompt.
            }
        }

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .apply { if (!subtitle.isNullOrEmpty()) setSubtitle(subtitle) }
            .setDescription(reason)
            .setAllowedAuthenticators(authenticators)
            .setConfirmationRequired(false)
            .build()

        try {
            val prompt = BiometricPrompt(activity, executor, callback)
            biometricPrompt = prompt
            prompt.authenticate(promptInfo)
        } catch (e: Throwable) {
            Log.w(TAG, "BiometricPrompt threw during authenticate(); falling back to keyguard", e)
            launchKeyguardFallback(title, subtitle ?: reason)
        }
    }

    @Suppress("DEPRECATION")
    private fun launchKeyguardFallback(title: String, description: String) {
        val keyguard = activity.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (!keyguard.isDeviceSecure) {
            completeError("NO_DEVICE_CREDENTIAL", "Device has no lock-screen credential set")
            return
        }
        val intent: Intent? = keyguard.createConfirmDeviceCredentialIntent(title, description)
        if (intent == null) {
            completeError("NO_INTENT", "Unable to build confirm-credential intent")
            return
        }
        try {
            activity.startActivityForResult(intent, REQUEST_CONFIRM_CREDENTIAL)
        } catch (e: Throwable) {
            Log.e(TAG, "startActivityForResult failed", e)
            completeError("INTENT_FAILED", e.message ?: "intent launch failed")
        }
    }

    private fun completeWith(success: Boolean) {
        biometricPrompt = null
        pendingResult.getAndSet(null)?.success(success)
    }

    private fun completeError(code: String, message: String) {
        biometricPrompt = null
        pendingResult.getAndSet(null)?.error(code, message, null)
    }
}
