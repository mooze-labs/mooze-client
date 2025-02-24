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
      backgroundColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFFD973C1),
      unselectedItemColor: Colors.white70,
      onTap: onItemTapped,
      items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/up-long-solid.svg',
            color: _iconColor(0),
            width: 24,
            height: 24,
          ),
          label: "Enviar",
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/down-long-solid.svg',
            color: _iconColor(1),
            width: 24,
            height: 24,
          ),
          label: "Receber",
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/right-left-solid.svg',
            color: _iconColor(2),
            width: 24,
            height: 24,
          ),
          label: "Swap",
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/pix-brands-solid.svg',
            color: _iconColor(3),
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
        ? const Color(0xFFD973C1) // selected
        : Colors.white70;        // unselected
  }
}
