import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const double logoOpacity = 0.2;
const String logoPath = 'assets/new_ui_wallet/assets/logos/logo_primary.svg';
const double logoWidth = 117.0;
const double logoHeight = 24.0;

class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
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
        const SizedBox(height: 30),
      ],
    );
  }
}
