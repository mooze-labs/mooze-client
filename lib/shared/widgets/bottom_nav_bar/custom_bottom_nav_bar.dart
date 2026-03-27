import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'bottom_nav_bar_painter.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          size: Size(MediaQuery.of(context).size.width, 110),
          // backgroundColor is injected here — painter has no context of its own
          painter: BottomNavBarPainter(
            backgroundColor: context.colors.navBarBackground,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 75,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: 'assets/icons/menu/navigation/home.svg',
                  index: 0,
                  label: 'Home',
                ),
                _buildNavItem(
                  icon: 'assets/icons/menu/navigation/asset.svg',
                  index: 1,
                  label: 'Ativos',
                ),
                SizedBox(width: 60),
                _buildNavItem(
                  icon: 'assets/icons/menu/navigation/swap.svg',
                  index: 3,
                  label: 'Swap',
                ),
                _buildNavItem(
                  icon: 'assets/icons/menu/navigation/menu.svg',
                  index: 4,
                  label: 'Menu',
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: MediaQuery.of(context).size.width / 2 - 30,
          top: 5,
          child: _buildCentralButton(),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required String icon,
    required int index,
    required String label,
  }) {
    final isSelected = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(10),
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SvgPicture.asset(
              icon,
              width: 25,
              height: 25,
              colorFilter:
                  isSelected
                      ? ColorFilter.mode(
                        context.colors.primaryColor,
                        BlendMode.srcIn,
                      )
                      : null,
            ),
            const SizedBox(height: 4),
            isSelected
                ? Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                )
                : SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralButton() {
    // LinearGradient uses runtime colors — cannot be const
    return GestureDetector(
      onTap: () => widget.onTap(2),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.colors.primaryColor,
              context.colors.navBarFabBackground,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: context.colors.primaryColor.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: SvgPicture.asset('assets/icons/menu/navigation/pix.svg'),
          ),
        ),
      ),
    );
  }
}
