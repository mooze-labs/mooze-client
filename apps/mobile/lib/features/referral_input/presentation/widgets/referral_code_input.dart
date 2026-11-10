import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/formatter/upper_case_text_formatter.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Text input field for entering a referral code.
///
/// A label above a glass field with the gift icon and uppercase formatting,
/// in the input style of the other glass screens: a lens fill, a hairline,
/// and the brand color on focus. When the API is down, the field is
/// disabled and muted.
class ReferralCodeInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isEnabled;
  final bool isApiDown;
  final VoidCallback onChanged;

  const ReferralCodeInput({
    super.key,
    required this.controller,
    required this.isEnabled,
    required this.isApiDown,
    required this.onChanged,
  });

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    final hairline = AppSurfaces.hairline(context);
    final muted = colors.textTertiary;

    OutlineInputBorder frame(Color color, double width) => OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: color, width: width),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            t.referral_input_label,
            style: context.textTheme.labelMedium?.copyWith(
              color: isApiDown ? muted : colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextField(
          autofocus: true,
          controller: controller,
          onChanged: (_) => onChanged(),
          enabled: isEnabled,
          inputFormatters: [UpperCaseTextFormatter()],
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          cursorColor: colors.primaryColor,
          style: context.textTheme.titleMedium?.copyWith(
            color: isApiDown ? muted : colors.textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
          decoration: InputDecoration(
            hintText: isApiDown
                ? t.referral_input_unavailable
                : t.referral_input_hint,
            hintStyle: context.textTheme.titleMedium?.copyWith(
              color: muted,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: SvgPicture.asset(
                'assets/icons/menu/settings/gift.svg',
                width: 22,
                height: 22,
                // A muted icon: the green of the hero marks the benefit, and
                // the brand color marks the focus.
                colorFilter: ColorFilter.mode(
                  isApiDown ? muted : colors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minHeight: 22),
            filled: true,
            fillColor: GlassStyle.of(context).lensFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: frame(hairline, 1),
            enabledBorder: frame(hairline, 1),
            disabledBorder: frame(hairline, 1),
            focusedBorder: frame(colors.primaryColor, 1.5),
          ),
        ),
      ],
    );
  }
}
