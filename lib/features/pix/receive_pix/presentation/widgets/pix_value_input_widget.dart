import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/extensions.dart';

import 'package:mooze_mobile/shared/formatters/fiat_input_formatter.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';

import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_validation_provider.dart';

import 'account_limits_display_widget.dart';

class PixValueInputWidget extends ConsumerWidget {
  final VoidCallback onContinue;

  const PixValueInputWidget({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: PixDepositAmountInput(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AccountLimitsDisplay(),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              t.pix_receive_my_level,
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colorScheme.onSurface,
                fontSize: context.responsiveFont(14),
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          // UserLevelDisplay manages its own internal padding —
          // no outer padding here to avoid double-spacing.
          const UserLevelDisplay(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class PixDepositAmountInput extends ConsumerStatefulWidget {
  const PixDepositAmountInput({super.key});

  @override
  ConsumerState<PixDepositAmountInput> createState() =>
      _PixDepositAmountInputState();
}

class _PixDepositAmountInputState extends ConsumerState<PixDepositAmountInput> {
  final TextEditingController _controller = TextEditingController(text: '0,00');
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(depositAmountProvider, (previous, next) {
        if (next == 0.0 && _controller.text != '0,00') {
          _controller.value = const TextEditingValue(
            text: '0,00',
            selection: TextSelection.collapsed(offset: 4),
          );
        }
      });
    });
  }

  void _onFocusChanged() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final depositAmountNotifier = ref.read(depositAmountProvider.notifier);
    final validation = ref.watch(depositValidationProvider);
    final levelsAsync = ref.watch(levelsProvider);
    final depositAmount = ref.watch(depositAmountProvider);

    final colorScheme = context.colorScheme;
    final isLoadingLimits = levelsAsync.isLoading;
    final hasValue = depositAmount > 0;
    final isError = !isLoadingLimits && !validation.isValid && hasValue;

    final Color valueColor;
    if (isLoadingLimits) {
      valueColor = colorScheme.onSurface.withValues(alpha: 0.38);
    } else if (isError) {
      valueColor = colorScheme.error;
    } else {
      valueColor = colorScheme.onSurface;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LayoutBuilder measures the real available width so we can derive a
        // font size that, when visually scaled by 1.4×, never overflows on
        // small screens. The left column (flag + BRL) always occupies ~110 px.
        LayoutBuilder(
          builder: (context, constraints) {
            const leftReserved = 110.0;
            const maxScale = 1.4;
            // "3.000,00" → 8 chars; 0.62 is an empirical char-width/fontSize
            // ratio for w600 numbers in a typical sans-serif font.
            const maxChars = 8;
            const charRatio = 0.62;

            final availableRight = constraints.maxWidth - leftReserved;
            final rawFontSize =
                availableRight / (maxScale * maxChars * charRatio);
            // Cap at 45 (user's design intent) and floor at 18 (readability).
            final fontSize = rawFontSize.clamp(18.0, 45.0);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: "Você adiciona" label + flag + currency code
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context).pix_receive_you_add,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: SvgPicture.asset(
                            'assets/flags/br.svg',
                            width: 26,
                            height: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BRL',
                          style: context.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Right: amount input — scales up on focus.
                // fontSize is pre-shrunk so that at 1.4× it still fits.
                Flexible(
                  child: AnimatedScale(
                    scale: _isFocused ? maxScale : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignment: Alignment.centerRight,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !isLoadingLimits,
                      maxLines: 1,
                      // Disable horizontal scroll — font shrinks instead.
                      scrollPhysics: const NeverScrollableScrollPhysics(),
                      style: TextStyle(
                        color: valueColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        filled: false,
                        hintText: '0,00',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.22),
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      inputFormatters: [_PixFiatInputFormatter()],
                      onChanged: (val) {
                        depositAmountNotifier
                            .state = FiatInputFormatter.parseValue(val);
                      },
                      onTapOutside: (_) {},
                      onSubmitted: (_) => _focusNode.unfocus(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        // Validation error — slides in below when amount is out of range
        Builder(
          builder: (context) {
            final localizedMessage = validation.localize(context);
            return AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child:
                  isError && localizedMessage != null
                      ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 14,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              localizedMessage,
                              style: context.textTheme.labelMedium?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                      : const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
}

// Caps input at 6 raw digits (R$ 3.000,00) to prevent the value text from
// overflowing the card layout on any screen size.
class _PixFiatInputFormatter extends FiatInputFormatter {
  static const int _maxRawDigits = 6;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > _maxRawDigits) return oldValue;
    return super.formatEditUpdate(oldValue, newValue);
  }
}
