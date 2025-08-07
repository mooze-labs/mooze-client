import 'package:flutter/material.dart';

const double iconSize = 28.0;
const double textSize = 18.0;

class MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Function() onTap;

  const MenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Theme.of(context).colorScheme.secondary,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: iconSize,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: textSize,
            fontFamily: "Inter",
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward,
          color: Theme.of(context).colorScheme.primary,
          size: iconSize,
        ),
        onTap: onTap,
      ),
    );
  }
}
