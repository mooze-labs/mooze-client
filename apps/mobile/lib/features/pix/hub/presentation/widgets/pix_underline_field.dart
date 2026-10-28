import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Text field drawn as a bare underline, as the send flow screens use it.
///
/// The app theme fills its fields with a box. This field sits on the page,
/// like the amount field: the text, then one line below it. The line is
/// thin at rest. It turns brand pink and thicker with the focus, and turns
/// to the error color with a message below.
class PixUnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final bool autofocus;
  final bool readOnly;
  final Widget? suffixIcon;

  const PixUnderlineField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.readOnly = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    UnderlineInputBorder line(Color color, double width) =>
        UnderlineInputBorder(
          borderSide: BorderSide(color: color, width: width),
        );
    final textStyle = context.textTheme.titleMedium?.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w500,
      // Documents and phone numbers line up digit by digit.
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      readOnly: readOnly,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      cursorColor: context.colors.primaryColor,
      style: textStyle,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: textStyle?.copyWith(
          color: context.colors.textTertiary,
          fontWeight: FontWeight.w400,
        ),
        errorText: errorText,
        errorMaxLines: 3,
        errorStyle: context.textTheme.bodySmall?.copyWith(
          color: context.colors.negativeColor,
          height: 1.4,
        ),
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
        // The field sits on the page, where the light outline variant has
        // the page color. The outline shows in both themes.
        border: line(context.colorScheme.outline, 1),
        enabledBorder: line(context.colorScheme.outline, 1),
        disabledBorder: line(context.colorScheme.outline, 1),
        focusedBorder: line(context.colors.primaryColor, 2),
        errorBorder: line(context.colors.negativeColor, 1),
        focusedErrorBorder: line(context.colors.negativeColor, 2),
        suffixIcon: suffixIcon,
        // Icon buttons in the suffix keep their 48 pt touch target.
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
      ),
    );
  }
}
