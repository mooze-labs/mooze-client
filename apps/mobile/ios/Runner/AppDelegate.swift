import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    PrivacyCover.shared.install()
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

    PrivacyCover.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger()
    )
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

/// Hides the app behind a cover as it leaves the foreground: a picture of
/// the privacy shield of Flutter, which the Dart side paints off the screen
/// ahead of time, on the color of the backdrop until the first picture.
///
/// The privacy shield of Flutter needs a new frame, and iOS does not wait
/// for it: it may take the snapshot of the app switcher, or stop drawing the
/// app as the screen turns off, before that frame is on screen. This cover
/// is a view of the window, so iOS draws it at once, inside the very
/// notification that the scene is leaving.
///
/// The Dart side (`NativePrivacyCoverBridge`) sets its look, keeps it down
/// while one of our own system prompts is up (Face ID, the alert of a
/// clipboard read), which deactivates the app without leaving it, and
/// releases it once Flutter has drawn the app back. Should that never come,
/// the cover leaves on its own after a moment.
///
/// It listens to the notifications of the scene rather than overriding the
/// scene delegate, so the lifecycle of Flutter stays as it is.
final class PrivacyCover {
  static let shared = PrivacyCover()

  /// Time after the app is back before the cover leaves by itself.
  private static let fallbackDelay: TimeInterval = 1.5

  /// Time of the fade of the cover as it leaves.
  private static let fadeDuration: TimeInterval = 0.2

  private var color: UIColor = .systemBackground
  private var image: UIImage?
  /// Counts the pictures sent, so a picture decoded late never replaces a
  /// newer one.
  private var imageRequests = 0
  private let decoder = DispatchQueue(
    label: "com.mooze.privacy_cover.decode", qos: .userInitiated)
  private var suppressed = false
  private var cover: UIView?
  private var picture: UIImageView?
  private var fallback: DispatchWorkItem?
  private var installed = false

  private init() {}

  /// Listens to the scene. Without a queue, each block runs at once, on
  /// the main thread that posts the notification.
  func install() {
    guard !installed else { return }
    installed = true
    let center = NotificationCenter.default
    center.addObserver(
      forName: UIScene.willDeactivateNotification, object: nil, queue: nil
    ) { [weak self] note in
      guard let self, !self.suppressed else { return }
      self.raise(over: note.object as? UIWindowScene)
    }
    // A real trip out of the app: covered even under a prompt of ours.
    center.addObserver(
      forName: UIScene.didEnterBackgroundNotification, object: nil, queue: nil
    ) { [weak self] note in
      self?.raise(over: note.object as? UIWindowScene)
    }
    center.addObserver(
      forName: UIScene.didActivateNotification, object: nil, queue: nil
    ) { [weak self] _ in
      self?.releaseLater()
    }
  }

  /// Answers `NativePrivacyCoverBridge`.
  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.mooze/privacy_cover", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      switch call.method {
      case "setColor":
        if let argb = (call.arguments as? NSNumber)?.uint32Value {
          self.color = UIColor(argb: argb)
        }
        result(nil)
      case "setImage":
        if let args = call.arguments as? [String: Any],
          let png = (args["png"] as? FlutterStandardTypedData)?.data,
          let scale = (args["scale"] as? NSNumber)?.doubleValue
        {
          self.prepare(png: png, scale: CGFloat(scale))
        }
        result(nil)
      case "setSuppressed":
        self.suppressed = (call.arguments as? Bool) ?? false
        result(nil)
      case "release":
        self.release()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Decodes the picture ahead of time, away from the main thread.
  ///
  /// A PNG decodes the first time it shows: on the main thread, inside the
  /// very commit that puts the cover on screen. For the picture of a whole
  /// screen that takes tens of milliseconds, time in which iOS may already
  /// take the snapshot of the app switcher: the first cover after a new
  /// picture would come too late. The decoded picture shows at once.
  private func prepare(png: Data, scale: CGFloat) {
    imageRequests += 1
    let request = imageRequests
    decoder.async { [weak self] in
      let picture = UIImage(data: png, scale: scale)
      let decoded = picture?.preparingForDisplay() ?? picture
      DispatchQueue.main.async {
        guard let self, request == self.imageRequests, let decoded else { return }
        self.image = decoded
      }
    }
  }

  private func raise(over scene: UIWindowScene?) {
    fallback?.cancel()
    fallback = nil
    guard let scene,
      let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
    else { return }
    let view = cover ?? UIView()
    view.layer.removeAllAnimations()
    view.alpha = 1
    view.backgroundColor = color
    view.frame = window.bounds
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    let shield = picture ?? UIImageView()
    shield.image = image
    shield.contentMode = .scaleAspectFill
    shield.frame = view.bounds
    shield.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(shield)
    picture = shield
    // On top of everything the window shows, again if it is already there.
    window.addSubview(view)
    cover = view
    // On screen now, inside the notification, rather than at the end of
    // this turn of the run loop, after whatever else handles it.
    CATransaction.flush()
  }

  private func release() {
    fallback?.cancel()
    fallback = nil
    guard let view = cover else { return }
    cover = nil
    picture = nil
    UIView.animate(
      withDuration: Self.fadeDuration,
      animations: { view.alpha = 0 },
      completion: { _ in view.removeFromSuperview() })
  }

  private func releaseLater() {
    fallback?.cancel()
    let item = DispatchWorkItem { [weak self] in self?.release() }
    fallback = item
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.fallbackDelay, execute: item)
  }
}

extension UIColor {
  /// A color from 0xAARRGGBB, as Flutter writes it.
  fileprivate convenience init(argb: UInt32) {
    self.init(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255)
  }
}
