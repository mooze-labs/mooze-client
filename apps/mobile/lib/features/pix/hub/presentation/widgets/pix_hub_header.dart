import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Header of the Pix hub.
///
/// It repeats the logo of the home screen, moved to the left, and keeps the
/// scanner and the information actions on the right.
///
/// The hub pins it above the scrolling content: it is transparent while the
/// list sits at the top. Once the user scrolls, it paints its slice of the
/// screen backdrop (see [AppBackdrop]), so the content never shows through
/// it and the header still blends with the backdrop. The background
/// cross-fades over [Motion.durationFast]. With reduced motion, it changes
/// at once.
class PixHubHeader extends StatelessWidget {
  /// Opens the QR Code scanner.
  final VoidCallback onScan;

  /// Opens the guidance about how Pix works.
  final VoidCallback onInfo;

  /// True once the list scrolled away from the top.
  final bool isScrolled;

  /// Distance from the screen edges to the logo and to the action buttons.
  ///
  /// The hub sends its content gutter, so the header aligns with the cards.
  final double horizontalPadding;

  /// Distance from the top of the screen to the top of the header. The
  /// header uses it to paint the matching slice of the backdrop.
  final double backdropOrigin;

  const PixHubHeader({
    super.key,
    required this.onScan,
    required this.onInfo,
    this.isScrolled = false,
    this.horizontalPadding = 20,
    this.backdropOrigin = 0,
  });

  /// Height the hub reserves for the pinned header.
  static const double height = 56;

  /// Same asset, size and tint used by the home screen header.
  static const String _logoPath = 'assets/logos/logo_primary.svg';
  static const double _logoWidth = 117;
  static const double _logoHeight = 24;
  static const double _logoOpacity = 0.2;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final duration = Motion.of(context, Motion.durationFast);

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: isScrolled ? 1 : 0,
            duration: duration,
            curve: Motion.curveMove,
            child: AppBackdrop(origin: backdropOrigin),
          ),
        ),
        AnimatedContainer(
          duration: duration,
          curve: Motion.curveMove,
          height: height,
          // The touch target of each action is larger than its visible
          // circle. The smaller right padding aligns the circle with the
          // content edge.
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding - _HeaderAction.touchInset,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                // The same hairline as the glass panels below the header.
                color: isScrolled
                    ? AppSurfaces.hairline(context)
                    : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                _logoPath,
                width: _logoWidth,
                height: _logoHeight,
                colorFilter: ColorFilter.mode(
                  context.colorScheme.onSurface.withValues(alpha: _logoOpacity),
                  BlendMode.srcIn,
                ),
              ),
              const Spacer(),
              _HeaderAction(
                icon: PixIcons.scan,
                tooltip: t.pix_hub_action_pay_qr,
                onPressed: onScan,
              ),
              _HeaderAction(
                icon: PixIcons.info,
                tooltip: t.pix_hub_info_title,
                onPressed: onInfo,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Round action button of the header.
///
/// The soft circle groups the two actions and shows their touch area.
class _HeaderAction extends StatelessWidget {
  final PixIconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  static const double _size = 40;

  /// Space between the visible circle and the 48 pt touch target.
  static const double touchInset = (kMinInteractiveDimension - _size) / 2;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: PixIcon(icon, size: 20, color: context.colors.textPrimary),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(_size),
        minimumSize: const Size.square(_size),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.padded,
        // A glass lens, like the icon wells of the lists.
        backgroundColor: GlassStyle.of(context).lensFill,
        foregroundColor: context.colors.textPrimary,
        side: BorderSide(color: AppSurfaces.hairline(context)),
      ),
    );
  }
}
