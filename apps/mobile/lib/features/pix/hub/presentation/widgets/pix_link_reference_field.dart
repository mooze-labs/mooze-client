import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The reference of a payment link, drawn as a bare underline.
///
/// It follows the underline fields of the send flow. Unlike those, it keeps
/// sentence capitalization and suggestions, because it holds free text. The
/// create screen and the sheet that renames a link both use it.
class PixLinkReferenceField extends StatelessWidget {
  const PixLinkReferenceField({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    UnderlineInputBorder line(Color color, double width) =>
        UnderlineInputBorder(
          borderSide: BorderSide(color: color, width: width),
        );
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      style: context.textTheme.titleMedium?.copyWith(
        color: context.colors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: t.pix_hub_link_reference_hint,
        hintStyle: context.textTheme.titleMedium?.copyWith(
          color: context.colors.textTertiary,
        ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        // The field sits on the page or on a glass sheet, where the light
        // outline variant has the surface color. The outline shows in both
        // themes.
        border: line(context.colorScheme.outline, 1),
        enabledBorder: line(context.colorScheme.outline, 1),
        focusedBorder: line(context.colors.primaryColor, 1.5),
      ),
    );
  }
}
