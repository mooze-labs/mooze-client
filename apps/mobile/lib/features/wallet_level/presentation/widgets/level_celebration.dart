import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/utils/wallet_level_ui_helpers.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/level_emblem.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_face.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_turn.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// The entrance of a level change, on the stage of the level screens: the
/// medal of the old level turns to the medal of the new one, see
/// [StageTurn]. Each medal and its light take the color of its level.
///
/// Up, the medal spins up to the new level with a flash and a shockwave.
/// Down, it turns once, slowly, and sinks a little.
///
/// [animation] runs from 0 to 1 over [Motion.durationLevelChange].
class LevelCelebration extends StatelessWidget {
  const LevelCelebration({
    super.key,
    required this.oldLevel,
    required this.newLevel,
    required this.animation,
  });

  final int oldLevel;
  final int newLevel;
  final Animation<double> animation;

  bool get isUpgrade => newLevel > oldLevel;

  /// Height of the stage. The shockwave and the light reach past it.
  static const double height = 280;

  /// Width of the medal, from side to side.
  static const double medalSize = 128;

  /// Progress at which the medal starts to spin up.
  static const double spinAt = StageTurn.spinAt;

  /// Progress at which the new level shows up.
  static const double upRevealAt = StageTurn.upRevealAt;

  /// Progress at which the medal lands up.
  static const double landAt = StageTurn.landAt;

  /// Progress at which the new level shows down.
  static const double downRevealAt = StageTurn.downRevealAt;

  /// The shape of the medals: a hexagon with rounded corners.
  static const _medalShape = StarBorder.polygon(sides: 6, pointRounding: 0.24);

  @override
  Widget build(BuildContext context) {
    final palette = StagePalette.of(context);
    final brightness = Theme.of(context).brightness;
    final oldTint = WalletLevelUiHelpers.getLevelTint(oldLevel, brightness);
    final newTint = WalletLevelUiHelpers.getLevelTint(newLevel, brightness);

    Widget medal(int level, Color tint) => StageFace(
      shape: _medalShape,
      size: medalSize,
      tint: tint,
      palette: palette,
      glyph: (color) => LevelEmblem(level, size: medalSize * 0.5, color: color),
    );

    return StageTurn(
      animation: animation,
      upward: isUpgrade,
      shape: _medalShape,
      size: medalSize,
      height: height,
      from: medal(oldLevel, oldTint),
      to: medal(newLevel, newTint),
      fromTint: oldTint,
      toTint: newTint,
    );
  }
}
