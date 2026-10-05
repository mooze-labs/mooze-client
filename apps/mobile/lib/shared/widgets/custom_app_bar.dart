import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final InlineSpan title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.backgroundColor,
      elevation: 0,
      title: RichText(text: title),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: context.colors.textPrimary,
        ),
        onPressed: onBack ?? () => Navigator.pop(context),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
