import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// Returns the Hero tag of the icon of [asset].
///
/// Use the tag once per route. The home asset row and the asset detail
/// app bar share it.
Object assetIconHeroTag(Asset asset) => 'asset-icon-${asset.id}';

/// The icon of [asset] as a Hero.
///
/// The flight follows the route transition, so the global page transitions
/// set its timing. With reduced motion, the Hero does not fly.
class AssetIconHero extends StatelessWidget {
  const AssetIconHero({super.key, required this.asset, required this.size});

  final Asset asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: !Motion.isReduced(context),
      child: Hero(
        tag: assetIconHeroTag(asset),
        child: SvgPicture.asset(asset.iconPath, width: size, height: size),
      ),
    );
  }
}
