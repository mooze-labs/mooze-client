import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_scene.dart';
import 'package:mooze_mobile/shared/clipboard/clipboard_reader.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';

import '../auth_prompt_controller.dart';
import '../lock_seal_provider.dart';
import 'paint_offscreen.dart';
import 'privacy_shield_overlay.dart';

/// Drives the native privacy cover of iOS, which `AppDelegate.swift` lays
/// over the window as the app leaves the foreground.
///
/// The privacy shield of Flutter (see `PrivacyShieldOverlay`) needs a new
/// frame to show, and iOS does not wait for it: it may take the snapshot of
/// the app switcher, or stop drawing the app as the screen turns off, before
/// that frame is on screen. The wallet then shows in the app switcher, or
/// for a moment when the screen turns back on. The native cover is drawn by
/// iOS itself, at once, so neither can happen.
///
/// The bridge tells the cover:
/// - its look: a picture of the privacy shield of Flutter, painted off the
///   screen while the app is idle, so the cover of iOS is the same as ours;
///   until the first picture, the base of the backdrop of the theme;
/// - to stay down while one of our own system prompts is up, a biometric
///   prompt or the alert of a clipboard read, which take the app out of the
///   active state without leaving it;
/// - to leave once the app is back and Flutter has drawn its first frame,
///   with the lock or the privacy shield already in place, so the wallet
///   never shows in between.
///
/// It does nothing on other platforms. Put it in the `builder` of the app,
/// where the theme is known.
/// Paints [shield] at [size] and [pixelRatio] into a PNG, off the screen.
typedef ShieldPainter =
    Future<Uint8List?> Function(
      ui.FlutterView view,
      Widget shield,
      Size size,
      double pixelRatio,
    );

class NativePrivacyCoverBridge extends ConsumerStatefulWidget {
  const NativePrivacyCoverBridge({
    super.key,
    required this.child,
    this.snapshot = true,
    this.painter = paintShieldPng,
  });

  final Widget child;

  /// Whether it paints the picture of the shield for the cover.
  final bool snapshot;

  /// Paints the picture. Tests replace it.
  final ShieldPainter painter;

  /// Paints [shield] with [paintOffscreen] into a PNG.
  static Future<Uint8List?> paintShieldPng(
    ui.FlutterView view,
    Widget shield,
    Size size,
    double pixelRatio,
  ) async {
    final image = await paintOffscreen(
      view: view,
      child: shield,
      size: size,
      pixelRatio: pixelRatio,
    );
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      return png?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Time without a change of what the shield shows before the picture is
  /// painted again: a change of theme animates, and the picture waits for
  /// its end.
  static const snapshotDelay = Duration(milliseconds: 400);

  /// The channel of the cover, answered by `AppDelegate.swift`.
  static const channel = MethodChannel('com.mooze/privacy_cover');

  @override
  ConsumerState<NativePrivacyCoverBridge> createState() =>
      _NativePrivacyCoverBridgeState();
}

class _NativePrivacyCoverBridgeState
    extends ConsumerState<NativePrivacyCoverBridge>
    with WidgetsBindingObserver {
  bool? _suppressed;
  int? _color;
  ProviderSubscription<bool>? _prompt;
  ProviderSubscription<AsyncValue<BiometricKind?>>? _sealKind;
  Timer? _snapshotTimer;

  /// What the last picture shows, so an unchanged shield is not painted
  /// again.
  Object? _snapshotOf;

  /// Whether the platform has the cover, decided once, so [dispose] undoes
  /// exactly what [initState] did.
  late final bool _enabled =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (!_enabled) return;
    WidgetsBinding.instance.addObserver(this);
    _prompt = ref.listenManual(
      authPromptActiveProvider,
      (_, _) => _pushSuppressed(),
      fireImmediately: true,
    );
    ClipboardReader.reading.addListener(_pushSuppressed);
    if (widget.snapshot) {
      _sealKind = ref.listenManual(
        lockSealKindProvider,
        (_, _) => _scheduleSnapshot(),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_enabled) return;
    final color = BackdropStyle.of(context).base.toARGB32();
    if (color == _color) return;
    _color = color;
    _invoke('setColor', color);
    // The theme, the language or the screen may have changed.
    _scheduleSnapshot();
  }

  @override
  void dispose() {
    if (_enabled) {
      WidgetsBinding.instance.removeObserver(this);
      _prompt?.close();
      _sealKind?.close();
      _snapshotTimer?.cancel();
      ClipboardReader.reading.removeListener(_pushSuppressed);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _scheduleSnapshot();
    // The lock and the shield change in this same event: the first frame
    // after it already shows them.
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) _invoke('release');
    });
  }

  void _scheduleSnapshot() {
    if (!widget.snapshot) return;
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer(NativePrivacyCoverBridge.snapshotDelay, _snapshot);
  }

  /// Paints the shield as it shows now, off the screen, and sends the
  /// picture to the cover. Only in the foreground, where the app draws.
  Future<void> _snapshot() async {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!mounted ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    final media = MediaQuery.of(context).removeViewInsets(removeBottom: true);
    final kind = ref.read(lockSealKindProvider).valueOrNull;
    final of = (
      BackdropStyle.of(context).base,
      media.size,
      media.padding,
      media.devicePixelRatio,
      media.textScaler,
      Localizations.localeOf(context),
      kind,
    );
    if (of == _snapshotOf) return;
    final shield = MediaQuery(
      data: media,
      child: Localizations.override(
        context: context,
        child: InheritedTheme.captureAll(
          context,
          PrivacyShieldOverlay(sealKind: kind),
        ),
      ),
    );
    final Uint8List? png;
    try {
      png = await widget.painter(
        View.of(context),
        shield,
        media.size,
        media.devicePixelRatio,
      );
    } catch (_) {
      // The cover keeps its color.
      return;
    }
    if (!mounted || png == null) return;
    _snapshotOf = of;
    _invoke('setImage', {'png': png, 'scale': media.devicePixelRatio});
  }

  /// Sends the cover whether it stays down. The message goes before the
  /// call that opens the prompt, so the cover knows before iOS deactivates
  /// the app.
  void _pushSuppressed() {
    final suppressed =
        ref.read(authPromptActiveProvider) || ClipboardReader.reading.value;
    if (suppressed == _suppressed) return;
    _suppressed = suppressed;
    _invoke('setSuppressed', suppressed);
  }

  Future<void> _invoke(String method, [Object? arguments]) async {
    try {
      await NativePrivacyCoverBridge.channel.invokeMethod<void>(
        method,
        arguments,
      );
    } on MissingPluginException {
      // An engine without the cover, as in a test or an extension.
    } on PlatformException {
      // The cover is a safety net: the shield of Flutter stays.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
