import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_scene.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  group('BiometricFinale', () {
    test('every window ends by the rest of the scene, and the screen goes on '
        'once the check is drawn', () {
      for (final f in BiometricFinale.values) {
        for (final end in [
          f.lit,
          f.beamOut,
          f.checkDraws.$2,
          f.swell.$2,
          f.glow.$2,
          f.flashTo,
          f.waveTo,
          f.burstTo,
          f.handOffAt,
        ]) {
          expect(end, inInclusiveRange(0, 1), reason: '$f');
        }
        // The last sparkle of the kit starts at 0.76 and twinkles over 0.22.
        expect(0.76 + f.sparkleDelay + 0.22, lessThanOrEqualTo(1));
        // The peak falls while the check draws.
        expect(f.peakAt, inExclusiveRange(f.checkDraws.$1, f.checkDraws.$2));
        expect(f.handOffAt, greaterThanOrEqualTo(f.checkDraws.$2));
      }
    });

    test('an unlock shows the check at 0.3 s and goes on at 0.6 s', () {
      const f = BiometricFinale.check;
      expect(f.duration * f.peakAt, const Duration(milliseconds: 300));
      expect(f.duration * f.handOffAt, const Duration(milliseconds: 600));
    });

    test('an unlock never turns the seal, nor shows the coin', () {
      for (var s = 0.0; s <= 1; s += 0.02) {
        final seal = BiometricScene.sealAt(
          BiometricMotion(success: s),
          finale: BiometricFinale.check,
        );
        expect(seal.turn, closeTo(BiometricScene.restYaw, 1e-9));
        expect(seal.showsCoin, isFalse);
      }
    });

    testWidgets('an unlock has no hero: it never flies into the next page', (
      tester,
    ) async {
      Widget scene(BiometricFinale finale) => MaterialApp(
        home: Builder(
          builder: (context) => Theme(
            data: AppTheme.darkTheme(context),
            child: BiometricScene(
              kind: BiometricKind.fingerprint,
              motion: const BiometricMotion(success: 1),
              finale: finale,
            ),
          ),
        ),
      );
      await tester.pumpWidget(scene(BiometricFinale.check));
      expect(find.byType(Hero), findsNothing);
      await tester.pumpWidget(scene(BiometricFinale.coin));
      expect(find.byType(Hero), findsOneWidget);
    });
  });
}
