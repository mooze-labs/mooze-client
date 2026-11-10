import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/utils/wallet_level_ui_helpers.dart';
import 'package:mooze_mobile/shared/widgets/stage/glyph_colors.dart';

/// The emblem of a wallet [level] in one [color], by default the tint of
/// the level in the theme. The emblem is decorative: the name of the level
/// goes next to it.
class LevelEmblem extends StatelessWidget {
  const LevelEmblem(this.level, {super.key, required this.size, this.color});

  final int level;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      WalletLevelUiHelpers.getLevelEmblem(level),
      width: size,
      height: size,
      excludeFromSemantics: true,
      colorMapper: TwoToneGlyphColors(
        color ??
            WalletLevelUiHelpers.getLevelTint(
              level,
              Theme.of(context).brightness,
            ),
      ),
    );
  }
}
