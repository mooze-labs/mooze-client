import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MoozeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  MoozeAppBar({required this.title, super.key});

  @override
  PreferredSizeWidget build(BuildContext context) {
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
