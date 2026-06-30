import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/v2_providers.dart';
import '../session/privacy_shield_controller.dart';
import '../session/privacy_shield_state.dart';
import '../session/session_lock_controller.dart';

/// Bridges Flutter's `AppLifecycleState` into the V2 transaction notifier's
/// foreground gate and drives the global session lock / privacy shield.
/// Mounted near the app root; does not render any UI.
class AppForegroundObserver extends ConsumerStatefulWidget {
  final Widget child;

  const AppForegroundObserver({super.key, required this.child});

  @override
  ConsumerState<AppForegroundObserver> createState() =>
      _AppForegroundObserverState();
}

class _AppForegroundObserverState extends ConsumerState<AppForegroundObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final privacyShield = ref.read(privacyShieldControllerProvider.notifier);
    final sessionLock = ref.read(sessionLockControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        // Resolve the lock first (it may flip to `locked`), then drop the
        // shield — the gate keeps an auth cover up whenever locked.
        sessionLock.onResumed();
        privacyShield.onResumed();
        break;
      case AppLifecycleState.inactive:
        // Raise the shield while still rendering on the way out, so it becomes
        // the last painted frame and the app-switcher snapshot. Also fires for
        // transient interruptions; the shield is dropped on resume when no real
        // backgrounding was recorded.
        privacyShield.onLeavingForeground();
        _forceShieldPaint();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Real backgrounding. Raise the shield again as a fallback (in case
        // `inactive` was coalesced) and start the session-lock timer.
        privacyShield.onLeavingForeground();
        _forceShieldPaint();
        sessionLock.onBackgrounded();
        break;
      case AppLifecycleState.detached:
        break;
    }

    final foregrounded = state == AppLifecycleState.resumed;
    // Best-effort: the notifier may not exist yet on splash. It defaults to
    // foregrounded=true on construction, so dropping the signal is safe.
    ref.read(transactionNotifierProvider.future).then((notifier) {
      notifier.setForegrounded(foregrounded);
    }).catchError((_) {});
  }

  /// Forces the shield frame to paint now rather than waiting for the next
  /// vsync. On a device screen-lock the display can go dark before Flutter
  /// paints the just-raised shield, leaving wallet content as the last painted
  /// frame (a brief flash on unlock). `scheduleWarmUpFrame` commits the shield
  /// frame immediately. Only forced when the shield actually went up.
  void _forceShieldPaint() {
    final shielded = ref.read(privacyShieldControllerProvider) ==
        PrivacyShieldState.visible;
    if (shielded) {
      WidgetsBinding.instance.scheduleWarmUpFrame();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
