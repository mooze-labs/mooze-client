import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lock_overlay_visibility.dart';
import '../privacy_shield_controller.dart';
import '../privacy_shield_state.dart';
import '../session_lock_controller.dart';
import '../session_lock_state.dart';
import 'wallet_lock_overlay.dart';

/// Combines the two independent security features — the privacy shield and the
/// session lock — into the single global overlay, mounted as the topmost child
/// of the `Stack` in `MaterialApp.router`'s `builder`.
///
/// There is intentionally no transition widget: an animated swap would blend
/// layers and expose content. The overlay toggles instantly and stays mounted
/// (see [WalletLockOverlay]). Cover/auth rules live in [resolveLockOverlay].
class SessionLockGate extends ConsumerWidget {
  const SessionLockGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shieldVisible =
        ref.watch(privacyShieldControllerProvider) ==
            PrivacyShieldState.visible;
    final locked =
        ref.watch(sessionLockControllerProvider) == SessionLockState.locked;

    final overlay = resolveLockOverlay(
      privacyShieldVisible: shieldVisible,
      sessionLocked: locked,
    );

    return WalletLockOverlay(
      showCover: overlay.showCover,
      showAuthentication: overlay.showAuthentication,
      onAuthenticated: () =>
          ref.read(sessionLockControllerProvider.notifier).unlock(),
    );
  }
}
