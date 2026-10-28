import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/models/user_levels.dart';

import 'package:mooze_mobile/shared/formatters/fiat_input_formatter.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';

import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_validation_provider.dart';

import 'account_limits_display_widget.dart';

/// Amount step of the deposit: the amount as the hero, then the limits.
///
/// The amount sits on the page with no card. The limits and the level of the
/// user follow in one glass summary.
class PixValueInputWidget extends ConsumerWidget {
  final VoidCallback onContinue;

  /// Optional onboarding-tutorial target keys (steps 6 & 7).
  final Key? amountKey;
  final Key? limitsKey;

  const PixValueInputWidget({
    super.key,
    required this.onContinue,
    this.amountKey,
    this.limitsKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(key: amountKey, child: const PixDepositAmountInput()),
        const SizedBox(height: 32),
        KeyedSubtree(
          key: limitsKey,
          child: const AccountLimitsDisplay(footer: _LevelRow()),
        ),
      ],
    );
  }
}

/// The deposit amount, drawn like the amount of the Pix hub.
///
/// Large digits with tabular figures and a muted currency symbol. A line
/// below the digits follows the focus and turns to the error color, with an
/// alert icon and a message, when the amount is out of the limits.
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

  /// Glyphs in the longest amount, "9.999,99".
  static const _maxGlyphs = 8;

  /// Average width of a bold tabular digit, as a fraction of the font size.
  static const _glyphWidthRatio = 0.62;

  /// Width of the currency symbol and its gap at 100% text size.
  static const _symbolWidth = 44.0;

  /// Smallest font size of the amount, for readability.
  static const _minFontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(depositAmountProvider, (previous, next) {
        if (_focusNode.hasFocus) return;
        final formatted = next <= 0
            ? '0,00'
            : FiatInputFormatter.formatValue(next);
        if (_controller.text != formatted) {
          _controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
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
    final t = AppLocalizations.of(context);
    final depositAmountNotifier = ref.read(depositAmountProvider.notifier);
    final validation = ref.watch(depositValidationProvider);
    final levelsAsync = ref.watch(levelsProvider);
    final depositAmount = ref.watch(depositAmountProvider);

    final isLoadingLimits = levelsAsync.isLoading;
    final hasValue = depositAmount > 0;
    final isError = !isLoadingLimits && !validation.isValid && hasValue;
    final message = isError ? validation.localize(context) : null;

    final Color valueColor;
    if (isLoadingLimits) {
      valueColor = context.colors.textPrimary.withValues(alpha: 0.38);
    } else if (isError) {
      valueColor = context.colors.negativeColor;
    } else {
      valueColor = context.colors.textPrimary;
    }

    final amountStyle = context.textTheme.headlineLarge;
    const tabular = [FontFeature.tabularFigures()];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.pix_receive_you_add,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        // The font size shrinks on narrow screens and with large text, so
        // the longest amount always fits on one line.
        LayoutBuilder(
          builder: (context, constraints) {
            final baseSize = amountStyle?.fontSize ?? 32;
            final textScale =
                MediaQuery.textScalerOf(context).scale(baseSize) / baseSize;
            final available = constraints.maxWidth - _symbolWidth * textScale;
            final fittedSize =
                available / (_maxGlyphs * _glyphWidthRatio * textScale);
            final fontSize = fittedSize.clamp(_minFontSize, baseSize);

            return GestureDetector(
              // A tap on the currency symbol also opens the keyboard.
              behavior: HitTestBehavior.opaque,
              onTap: isLoadingLimits ? null : _focusNode.requestFocus,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // A muted symbol keeps the eye on the digits.
                  Text(
                    r'R$',
                    style: context.textTheme.titleLarge?.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !isLoadingLimits,
                      maxLines: 1,
                      // Disable horizontal scroll — the font shrinks instead.
                      scrollPhysics: const NeverScrollableScrollPhysics(),
                      style: amountStyle?.copyWith(
                        color: valueColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        fontFeatures: tabular,
                      ),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        // The app theme fills its fields. The amount sits on
                        // the page, with the line below as its only frame.
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        filled: false,
                        hintText: '0,00',
                        hintStyle: amountStyle?.copyWith(
                          color: context.colors.textTertiary,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          fontFeatures: tabular,
                        ),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      inputFormatters: [_PixFiatInputFormatter()],
                      onChanged: (val) {
                        depositAmountNotifier.state =
                            FiatInputFormatter.parseValue(val);
                      },
                      onTapOutside: (_) {},
                      onSubmitted: (_) => _focusNode.unfocus(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: Motion.of(context, Motion.durationFast),
          curve: Motion.curveMove,
          height: _isFocused || isError ? 2 : 1,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: isError
                ? context.colors.negativeColor
                : _isFocused
                ? context.colors.primaryColor
                // The field sits on the page, where the light outline
                // variant has the page color. The outline shows in both
                // themes.
                : context.colorScheme.outline,
          ),
        ),
        // Validation error — slides in below when amount is out of range.
        SizeFadeSwitcher(
          child: message == null
              ? const SizedBox(
                  key: ValueKey('amount-valid'),
                  width: double.infinity,
                )
              : Padding(
                  key: ValueKey(message),
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: PixIcon(
                          PixIcons.error,
                          size: 15,
                          color: context.colors.negativeColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          message,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.negativeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Level of the user, as the last row of the limits summary.
///
/// The level sets the limits, so it sits with them. A tap opens the level
/// track in a glass sheet.
class _LevelRow extends ConsumerWidget {
  const _LevelRow();

  void _showLevels(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LevelSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final levels = ref.watch(levelsProvider);

    final Widget value = levels.when(
      data: (data) => Text(
        UserLevels.getLevelByOrder(data.spendingLevel)?.name ??
            data.currentLevelName,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      loading: () =>
          const SkeletonShimmer(child: SkeletonBox(width: 56, height: 12)),
      error: (_, _) => PixIcon(
        PixIcons.error,
        size: 16,
        color: context.colors.negativeColor,
        semanticLabel: t.level_load_error,
      ),
    );

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: () => _showLevels(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.pix_receive_my_level,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  value,
                  const SizedBox(width: 6),
                  PixIcon(
                    PixIcons.chevronRight,
                    size: 18,
                    color: context.colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass sheet with the level track of the user.
class _LevelSheet extends StatelessWidget {
  const _LevelSheet();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GlassSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      t.pix_receive_my_level,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t.common_close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: PixIcon(
                    PixIcons.close,
                    size: 20,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: UserLevelDisplay(),
            ),
          ],
        ),
      ),
    );
  }
}

// Caps input at 6 raw digits (R$ 9.999,99) to prevent the value text from
// overflowing the layout on any screen size.
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
