import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const double logoOpacity = 0.2;
const String logoPath = 'assets/logos/logo_primary.svg';
const double logoWidth = 117.0;
const double logoHeight = 24.0;

/// Height of the home header bar.
const double headerHeight = 56.0;

class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key, this.status});

  /// A status at the end of the header, such as the status island. It gets
  /// the room between the logo and the edge, so it never covers the logo.
  final Widget? status;

  /// Space kept between the logo and [status].
  static const double statusGap = 4;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    // Full width: the parent column aligns children to the start, so the
    // stack needs its own width to center the logo.
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
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
            if (status != null)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: (constraints.maxWidth - logoWidth) / 2 - statusGap,
                child: status,
              ),
          ],
        ),
      ),
    );
  }
}
