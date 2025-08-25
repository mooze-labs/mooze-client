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
          size: Size(MediaQuery.of(context).size.width, 100),
          painter: BottomNavBarPainter(),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 70,
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon:
                      'assets/new_ui_wallet/assets/icons/menu/navigation/home.svg',
                  index: 0,
                  label: 'Home',
                ),
                _buildNavItem(
                  icon:
                      'assets/new_ui_wallet/assets/icons/menu/navigation/asset.svg',
                  index: 1,
                  label: 'Ativos',
                ),
                const SizedBox(width: 60),
                _buildNavItem(
                  icon:
                      'assets/new_ui_wallet/assets/icons/menu/navigation/swap.svg',
                  index: 3,
                  label: 'Swap',
                ),
                _buildNavItem(
                  icon:
                      'assets/new_ui_wallet/assets/icons/menu/navigation/menu.svg',
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
      child: SizedBox(
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
                  style: const TextStyle(
                    color: Color(0xFFE91E63),
                    fontSize: 11,
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
            colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: SvgPicture.asset(
              'assets/new_ui_wallet/assets/icons/menu/navigation/pix.svg',
            ),
          ),
        ),
      ),
    );
  }
}
