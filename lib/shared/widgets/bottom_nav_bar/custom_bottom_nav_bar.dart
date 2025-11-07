import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
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
          painter: BottomNavBarPainter(),
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
                const SizedBox(width: 60),
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
    bool isSelected = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Container(
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
                        AppColors.primaryColor,
                        BlendMode.srcIn,
                      )
                      : null,
            ),
            const SizedBox(height: 4),
            isSelected
                ? Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                )
                : const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralButton() {
    return GestureDetector(
      onTap: () => widget.onTap(2),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryColor, AppColors.navBarFabBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
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
