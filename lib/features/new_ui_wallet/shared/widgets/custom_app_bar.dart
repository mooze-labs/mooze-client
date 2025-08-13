import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final InlineSpan title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.onBack,
    this.actions,
  }) : super(key: key);

  // Constants - Colors
  static const Color _backgroundColor = Color(0xFF0A0A0A);
  static const Color _cardBackground = Color(0xFF191818);
  static const Color _primaryColor = Color(0xFFEA1E63);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF9194A6);
  static const Color _textTertiary = Color(0xFF8E8E8E);
  static const Color _positiveColor = Colors.green;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _backgroundColor,
      elevation: 0,
      title: RichText(text: title),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primaryColor),
        onPressed: onBack ?? () => Navigator.pop(context),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}