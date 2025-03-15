import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MoozeBottomNav extends StatelessWidget {
  /// The currently selected BottomNav index.
  final int currentIndex;

  /// Callback to be invoked when an item is tapped.
  final ValueChanged<int> onItemTapped;

  const MoozeBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.white70,
      onTap: onItemTapped,
      items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/images/icons/up-long-solid.svg',
            color: _iconColor(0),
            width: 24,
            height: 24,
          ),
          label: "Enviar",
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/images/icons/down-long-solid.svg',
            color: _iconColor(1),
            width: 24,
            height: 24,
          ),
          label: "Receber",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wallet, size: 24.0, color: _iconColor(2)),
          label: "Carteira",
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/images/icons/right-left-solid.svg',
            color: _iconColor(3),
            width: 24,
            height: 24,
          ),
          label: "Swap",
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/images/icons/pix-brands-solid.svg',
            color: _iconColor(4),
            width: 24,
            height: 24,
          ),
          label: "Pix",
        ),
      ],
    );
  }

  /// Helper method to color icons
  Color _iconColor(int index) {
    return currentIndex == index
        ? Colors
            .pinkAccent // selected
        : Colors.white70; // unselected
  }
}
