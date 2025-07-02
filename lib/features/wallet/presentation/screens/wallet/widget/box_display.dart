import 'package:flutter/material.dart';

class WalletButtonBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  WalletButtonBox({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100.0,
        height: 100.0,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 40.0,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: "Inter",
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.tertiary,
                letterSpacing: 0.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
