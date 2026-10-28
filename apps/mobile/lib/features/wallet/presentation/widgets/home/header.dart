import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';

const double logoOpacity = 0.2;
const String logoPath = 'assets/logos/logo_primary.svg';
const double logoWidth = 117.0;
const double logoHeight = 24.0;

/// Height of the home header bar.
const double headerHeight = 56.0;

class LogoHeader extends ConsumerWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Full width: the parent column aligns children to the start, so the
    // stack needs its own width to center the logo.
    return SizedBox(
      width: double.infinity,
      height: headerHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: SvgPicture.asset(
              logoPath,
              width: logoWidth,
              height: logoHeight,
              colorFilter: ColorFilter.mode(
                Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: logoOpacity),
                BlendMode.srcIn,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: OfflineIndicator(
              onTap: () => OfflinePriceInfoOverlay.show(context),
            ),
          ),
        ],
      ),
    );
  }
}
