import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// iOS Liquid Glass variant of the bottom navigation bar.
///
/// Two glass capsules hold the tab items, and a glass orb between them holds
/// the Pix action. On Impeller each lens refracts the live page behind it,
/// so the scaffold must keep `extendBody: true`.
///
/// The bar keeps the same outer height (110) as the classic bar, so the
/// bottom padding of each page stays correct.
class LiquidGlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Key? centralButtonKey;

  const LiquidGlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.centralButtonKey,
  });

  static const double _barHeight = 110;
  static const double _capsuleHeight = 64;
  static const double _orbSize = 64;
  static const double _sideGutter = 16;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Lift the glass above the home indicator. Devices without an indicator
    // get a small fixed margin.
    final bottomOffset = bottomInset > 0 ? bottomInset - 8 : 12.0;

    return SizedBox(
      height: _barHeight,
      child: Stack(
        children: [
          Positioned(
            left: _sideGutter,
            right: _sideGutter,
            bottom: bottomOffset,
            height: _capsuleHeight,
            child: Row(
              children: [
                Expanded(
                  child: _GlassCapsule(
                    children: [
                      _buildNavItem(
                        context,
                        icon: 'assets/icons/menu/navigation/home.svg',
                        index: 0,
                        label: 'Home',
                      ),
                      _buildNavItem(
                        context,
                        icon: 'assets/icons/menu/navigation/asset.svg',
                        index: 1,
                        label: t.wallet_assets_tab,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: _gap),
                _buildPixOrb(context),
                const SizedBox(width: _gap),
                Expanded(
                  child: _GlassCapsule(
                    children: [
                      _buildNavItem(
                        context,
                        icon: 'assets/icons/menu/navigation/swap.svg',
                        index: 3,
                        label: t.swap_title,
                      ),
                      _buildNavItem(
                        context,
                        icon: 'assets/icons/menu/navigation/menu.svg',
                        index: 4,
                        label: 'Menu',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String icon,
    required int index,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? context.colors.primaryColor
        : context.colors.textPrimary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPixOrb(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(2),
      child: SizedBox(
        key: centralButtonKey,
        width: _orbSize,
        height: _orbSize,
        child: LiquidGlassLens(
          style: LiquidGlassStyle(
            shape: const LiquidGlassShape.continuousRoundedRectangle(
              cornerRadius: _orbSize / 2,
            ),
            appearance: LiquidGlassAppearance(
              // Brand tint keeps the Pix action recognizable on any page.
              color: context.colors.primaryColor.withValues(alpha: 0.55),
              blur: const LiquidGlassBlur(sigmaX: 2, sigmaY: 2),
              shadow: const LiquidGlassShadow(blur: 6, opacity: 0.25),
            ),
            refraction: const LiquidGlassRefraction(
              distortion: 0.14,
              distortionWidth: 22,
            ),
          ),
          touch: const LiquidGlassTouch.flexing(LiquidGlassFlex()),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: SvgPicture.asset('assets/icons/menu/navigation/pix.svg'),
            ),
          ),
        ),
      ),
    );
  }
}

/// A capsule-shaped glass lens that lays its children out in a row.
class _GlassCapsule extends StatelessWidget {
  final List<Widget> children;

  const _GlassCapsule({required this.children});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLens(
      style: LiquidGlassStyle(
        shape: const LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: LiquidGlassBottomNavBar._capsuleHeight / 2,
        ),
        appearance: LiquidGlassAppearance(
          // A light theme tint keeps labels legible over busy content.
          color: context.colors.navBarBackground.withValues(alpha: 0.45),
          blur: const LiquidGlassBlur(sigmaX: 4, sigmaY: 4),
          shadow: const LiquidGlassShadow(blur: 6, opacity: 0.18),
        ),
        refraction: const LiquidGlassRefraction(
          distortion: 0.1,
          distortionWidth: 26,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(children: children),
      ),
    );
  }
}
