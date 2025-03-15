import 'package:flutter/material.dart';

class MoozeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconButton? action;

  MoozeAppBar({required this.title, this.action, super.key});

  @override
  PreferredSizeWidget build(BuildContext context) {
    if (action != null) {
      return AppBar(
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "roboto",
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [action!],
      );
    }

    return AppBar(
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: "roboto",
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
