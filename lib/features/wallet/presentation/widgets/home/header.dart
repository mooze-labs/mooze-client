import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';

const double logoOpacity = 0.2;
const String logoPath = 'assets/new_ui_wallet/assets/logos/logo_primary.svg';
const double logoWidth = 117.0;
const double logoHeight = 24.0;

class LogoHeader extends ConsumerWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Stack(
          children: [
            // Logo centralizado
            Center(
              child: Opacity(
                opacity: logoOpacity,
                child: SvgPicture.asset(
                  logoPath,
                  width: logoWidth,
                  height: logoHeight,
                ),
              ),
            ),
            // Indicador offline no lado direito
            Positioned(
              right: 0,
              top: 0,
              child: OfflineIndicator(
                onTap: () => OfflinePriceInfoOverlay.show(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
