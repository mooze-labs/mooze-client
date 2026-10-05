package com.mooze.mooze

import android.content.Intent
import android.os.SystemClock
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.mooze.deviceinfo/boot_time"

    private lateinit var credentialBridge: CredentialAuthBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getBootTime") {
                val bootTime = getBootTime()
                result.success(bootTime)
            } else {
                result.notImplemented()
            }
        }

        credentialBridge = CredentialAuthBridge(this)
        credentialBridge.register(flutterEngine)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (::credentialBridge.isInitialized) {
            credentialBridge.onActivityResult(requestCode, resultCode)
        }
    }

    private fun getBootTime(): Long {
        // SystemClock.elapsedRealtime() returns time since boot
        // System.currentTimeMillis() returns current time
        // Subtracting one from the other gives us the boot timestamp
        return System.currentTimeMillis() - SystemClock.elapsedRealtime()
    }
}
