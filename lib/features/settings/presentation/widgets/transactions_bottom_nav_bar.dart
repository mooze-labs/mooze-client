import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class TransactionsBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const TransactionsBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<TransactionsBottomNavBar> createState() =>
      _TransactionsBottomNavBarState();
}

class _TransactionsBottomNavBarState extends State<TransactionsBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 95,
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                topLeft: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon:
                      'assets/new_ui_wallet/assets/icons/menu/navigation/asset.svg',
                  index: 0,
                  label: 'Transações',
                ),
                _buildNavItem(
                  icon:
                      'assets/new_ui_wallet/assets/icons/menu/navigation/swap.svg',
                  index: 1,
                  label: 'Swaps',
                ),
              ],
            ),
          ),
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
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SvgPicture.asset(
              icon,
              width: 25,
              height: 25,
              color: isSelected ? AppColors.primaryColor : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? AppColors.primaryColor
                        : AppColors.primaryIconColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
