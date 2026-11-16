import 'package:flutter/material.dart';

import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_scene.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The art of the cover of the app for a user who unlocks with a PIN alone:
/// the vault of the onboarding, a hexagon with a padlock on its face, on a
/// stage with its light, its ring, and its floor. It does not move.
///
/// It takes the room and the place of the biometric seal at rest (see
/// [BiometricScene]), with the same light and ring, so the cover reads the
/// same whichever way the user unlocks.
///
/// It is decorative: the title of the cover tells that the app is locked.
class LockVault extends StatelessWidget {
  const LockVault({super.key});

  /// Yaw of the vault: turned a little, so its depth shows, as the seal.
  static const double yaw = BiometricScene.restYaw;

  @override
  Widget build(BuildContext context) {
    final brand = context.colors.primaryColor;
    final palette = StagePalette.of(context);
    const size = BiometricScene.sealSize;
    final ring = stageRings[1];

    StageEffects effects(Canvas canvas) => StageEffects(
      canvas,
      tint: brand,
      light: palette.highlight(brand),
      radius: size / 2,
    );

    // The light, the dots, the floor and the ring of the seal at rest.
    return ExcludeSemantics(
      child: SizedBox(
        height: BiometricScene.height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            StagePaintLayer((canvas, area) {
              final center = area.center(Offset.zero);
              effects(canvas)
                ..glow(center, 0.55)
                ..dots(area, 0.5)
                ..floor(center, 0.6)
                ..ring(center, ring, StageLayer.back, appear: 1, orbit: 0.4);
            }),
            GlyphToken(
              glyphPath: stageVaultGlyph,
              size: size,
              yaw: yaw,
              tint: brand,
              palette: palette,
              shape: stageVaultShape,
            ),
            StagePaintLayer((canvas, area) {
              effects(canvas).ring(
                area.center(Offset.zero),
                ring,
                StageLayer.front,
                appear: 1,
                orbit: 0.4,
              );
            }),
          ],
        ),
      ),
    );
  }
}
