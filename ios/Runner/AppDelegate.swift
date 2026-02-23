import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let bootTimeChannel = FlutterMethodChannel(
      name: "com.mooze.deviceinfo/boot_time",
      binaryMessenger: controller.binaryMessenger
    )

    bootTimeChannel.setMethodCallHandler {
      (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getBootTime" {
        result(self.getBootTime())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func getBootTime() -> Int64 {
    // ProcessInfo.processInfo.systemUptime returns time since boot
    let uptime = ProcessInfo.processInfo.systemUptime
    let currentTime = Date().timeIntervalSince1970
    let bootTime = currentTime - uptime

    // Returns in milliseconds
    return Int64(bootTime * 1000)
  }
}
