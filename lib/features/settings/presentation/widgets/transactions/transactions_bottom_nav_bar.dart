import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/transactions/build_nav_item.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 95,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                topLeft: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AppNavItem(
                  icon: 'assets/icons/menu/navigation/asset.svg',
                  label: 'Transações',
                  index: 0,
                  currentIndex: widget.currentIndex,
                  onTap: () => widget.onTap(0),
                ),

                AppNavItem(
                  icon: 'assets/icons/menu/navigation/pix.svg',
                  label: 'Pix',
                  index: 1,
                  currentIndex: widget.currentIndex,
                  onTap: () => widget.onTap(1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
