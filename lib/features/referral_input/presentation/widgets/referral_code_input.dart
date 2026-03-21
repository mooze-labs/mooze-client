import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/shared/formatter/upper_case_text_formatter.dart';

/// Text input field for entering a referral code.
///
/// Features a floating label, gift SVG icon, and uppercase formatting.
/// Adapts its appearance when the API is down (disabled + grey state).
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final disabledColor = colorScheme.outlineVariant;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isApiDown ? disabledColor : colorScheme.primary,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/menu/settings/gift.svg',
                width: 24,
                height: 24,
                colorFilter:
                    isApiDown
                        ? ColorFilter.mode(disabledColor, BlendMode.srcIn)
                        : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => onChanged(),
                    enabled: isEnabled,
                    inputFormatters: [UpperCaseTextFormatter()],
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isApiDown
                              ? disabledColor
                              : colorScheme.onSurface,
                    ),
                    cursorColor: colorScheme.onSurface,
                    decoration: InputDecoration(
                      filled: false,
                      isCollapsed: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText:
                          isApiDown ? 'Indisponível' : 'Ex: MOOZE123',
                      hintStyle: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.normal,
                        color:
                            isApiDown
                                ? disabledColor
                                : colorScheme.onSurface
                                    .withValues(alpha: 0.54),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: colorScheme.surfaceDim,
            child: Text(
              'Código de Indicação',
              style: textTheme.bodySmall?.copyWith(
                color:
                    isApiDown
                        ? disabledColor
                        : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
