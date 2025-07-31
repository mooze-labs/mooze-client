import 'package:flutter/material.dart';

import '../consts.dart';

class SectionHeader extends StatelessWidget {
  final VoidCallback onAction;
  final String title;
  final String actionDescription;

  const SectionHeader({super.key, required this.onAction, required this.title, required this.actionDescription});

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: sectionTitleFontSize,
                fontWeight: FontWeight.bold),
          ),
          GestureDetector(
              onTap: onAction,
              child: Text(
                  actionDescription,
                  style: TextStyle(color: Theme.of(context).colorScheme.onTertiary, fontSize: 14)
              )
          )
        ]
    );
  }
}
