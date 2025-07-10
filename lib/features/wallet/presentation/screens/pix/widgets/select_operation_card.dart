import 'package:flutter/material.dart';

class SelectOperationCard extends StatelessWidget {
  const SelectOperationCard({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.subtext,
  });

  final String text;
  final String? subtext;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            color: Theme.of(context).colorScheme.tertiary,
            fontFamily: "Inter",
          ),
        ),
        subtitle:
            subtext != null
                ? Text(
                  subtext!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                )
                : null,
        leading: icon,
        onTap: onTap,
      ),
    );
  }
}
