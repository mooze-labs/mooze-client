package com.mooze.mooze

import android.os.SystemClock
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.mooze.deviceinfo/boot_time"

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
    }

    private fun getBootTime(): Long {
        // SystemClock.elapsedRealtime() returns time since boot
        // System.currentTimeMillis() returns current time
        // Subtracting one from the other gives us the boot timestamp
        return System.currentTimeMillis() - SystemClock.elapsedRealtime()
    }
}
