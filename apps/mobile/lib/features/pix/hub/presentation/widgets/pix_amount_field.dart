import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/shared/formatters/fiat_input_formatter.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Currency field used by every amount step of the hub.
///
/// The amount is the hero of the step: large digits with tabular figures,
/// and a muted currency symbol. A line below the digits follows the focus
/// and turns to the error color with a message and an alert icon, so an
/// error never depends on color alone.
///
/// The field reports the amount in BRL cents, which is the unit every hub
/// entity stores.
class PixAmountField extends StatefulWidget {
  /// Called on every change, with the amount in BRL cents.
  final ValueChanged<int> onChanged;

  /// Amount shown when the field appears, in BRL cents.
  final int initialAmountInCents;

  /// Message shown below the field, or null when the amount is accepted.
  final String? errorText;

  /// Opens the keyboard as soon as the screen appears.
  final bool autofocus;

  /// Blocks typing, used when a scanned code fixed the amount.
  final bool readOnly;

  /// Focus of the field. The field makes its own when this is null.
  final FocusNode? focusNode;

  /// Keyboard action, for example [TextInputAction.next] when another field
  /// follows.
  final TextInputAction? textInputAction;

  /// Called when the user presses the keyboard action.
  final VoidCallback? onSubmitted;

  const PixAmountField({
    super.key,
    required this.onChanged,
    this.initialAmountInCents = 0,
    this.errorText,
    this.autofocus = true,
    this.readOnly = false,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<PixAmountField> createState() => _PixAmountFieldState();
}

class _PixAmountFieldState extends State<PixAmountField> {
  late final TextEditingController _controller;
  FocusNode? _ownFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    // The underline follows the focus.
    _focusNode.addListener(_onFocusChange);
    _controller = TextEditingController(
      text: widget.initialAmountInCents > 0
          ? FiatInputFormatter.formatValue(widget.initialAmountInCents / 100)
          : '0,00',
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ownFocusNode?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PixAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final focused = _focusNode.hasFocus && !widget.readOnly;
    final duration = Motion.of(context, Motion.durationFast);
    const tabular = [FontFeature.tabularFigures()];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                autofocus: widget.autofocus,
                readOnly: widget.readOnly,
                textInputAction: widget.textInputAction,
                onSubmitted: (_) => widget.onSubmitted?.call(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [FiatInputFormatter()],
                style: context.textTheme.headlineLarge?.copyWith(
                  color: hasError
                      ? context.colors.negativeColor
                      : context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  fontFeatures: tabular,
                ),
                decoration: const InputDecoration(
                  // The app theme fills its fields. The amount sits on the
                  // page, with the line below as its only frame.
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (text) {
                  // The formatter always writes two decimals, so the digits
                  // are the cents. No amount passes through a double.
                  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
                  widget.onChanged(int.tryParse(digits) ?? 0);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: duration,
          curve: Motion.curveMove,
          height: focused || hasError ? 2 : 1,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: hasError
                ? context.colors.negativeColor
                : focused
                ? context.colors.primaryColor
                // The field sits on the page, where the light outline
                // variant has the page color. The outline shows in both
                // themes.
                : context.colorScheme.outline,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 10),
          Row(
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
                  widget.errorText!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.negativeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
