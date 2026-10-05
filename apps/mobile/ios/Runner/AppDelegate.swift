import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let bootTimeChannel = FlutterMethodChannel(
      name: "com.mooze.deviceinfo/boot_time",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    bootTimeChannel.setMethodCallHandler { [weak self]
      (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getBootTime", let self = self {
        result(self.getBootTime())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
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
