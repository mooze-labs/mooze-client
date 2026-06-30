import 'package:flutter_test/flutter_test.dart';

import 'package:mooze_mobile/app/session/lock_overlay_visibility.dart';

void main() {
  group('resolveLockOverlay', () {
    test('unlocked + shield hidden → nothing painted', () {
      final r = resolveLockOverlay(
        privacyShieldVisible: false,
        sessionLocked: false,
      );
      expect(r.showCover, isFalse);
      expect(r.showAuthentication, isFalse);
    });

    test('shield visible (backgrounded), unlocked → branded cover, no auth',
        () {
      final r = resolveLockOverlay(
        privacyShieldVisible: true,
        sessionLocked: false,
      );
      expect(r.showCover, isTrue);
      expect(r.showAuthentication, isFalse);
    });

    test('locked, shield hidden (resumed) → cover + auth UI', () {
      final r = resolveLockOverlay(
        privacyShieldVisible: false,
        sessionLocked: true,
      );
      expect(r.showCover, isTrue);
      expect(r.showAuthentication, isTrue);
    });

    test(
        'locked AND shield visible (e.g. biometric prompt fired inactive) → '
        'auth wins, stays mounted', () {
      // Auth takes precedence while locked: the locked PIN screen is itself an
      // opaque cover with no wallet content, so the shield must NOT swap it out
      // — doing so would interrupt the biometric prompt and remount the screen
      // in a loop.
      final r = resolveLockOverlay(
        privacyShieldVisible: true,
        sessionLocked: true,
      );
      expect(r.showCover, isTrue);
      expect(r.showAuthentication, isTrue);
    });
  });
}
