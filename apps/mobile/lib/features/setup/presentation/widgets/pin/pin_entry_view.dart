import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_dots.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_keypad.dart';

/// The body of a PIN entry screen: the header at the top, the PIN dots in
/// the middle of the free space, and the keypad and the main button at the
/// bottom, near the thumb.
///
/// The keypad writes to [controller], so the screen keeps its own
/// validation and actions. The controller never holds more than [length]
/// digits.
///
/// A rise of [errorCount] shakes the dots and paints them in the error
/// color until the next digit.
class PinEntryView extends StatefulWidget {
  const PinEntryView({
    super.key,
    required this.controller,
    required this.header,
    required this.action,
    this.length = 6,
    this.errorCount = 0,
    this.enabled = true,
    this.leadingKey,
    this.footer,
  });

  final TextEditingController controller;
  final Widget header;

  /// Main button below the keypad.
  final Widget action;

  final int length;

  /// Number of failed attempts so far (see [PinDots.errorCount]).
  final int errorCount;

  /// Turns the keypad off, for example while the PIN is checked.
  final bool enabled;

  /// Optional key at the bottom left of the keypad.
  final Widget? leadingKey;

  /// Optional content below the main button.
  final Widget? footer;

  @override
  State<PinEntryView> createState() => _PinEntryViewState();
}

class _PinEntryViewState extends State<PinEntryView> {
  bool _showError = false;

  @override
  void didUpdateWidget(PinEntryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorCount > oldWidget.errorCount) _showError = true;
  }

  void _addDigit(String digit) {
    final text = widget.controller.text;
    if (text.length >= widget.length) return;
    setState(() => _showError = false);
    widget.controller.text = text + digit;
  }

  void _removeDigit() {
    final text = widget.controller.text;
    if (text.isEmpty) return;
    widget.controller.text = text.substring(0, text.length - 1);
  }

  void _clear() => widget.controller.clear();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.header,
        const SizedBox(height: 24),
        const Spacer(),
        Center(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) => PinDots(
              length: widget.length,
              filled: value.text.length,
              errorCount: widget.errorCount,
              hasError: _showError,
            ),
          ),
        ),
        const Spacer(),
        const SizedBox(height: 24),
        PinKeypad(
          enabled: widget.enabled,
          leadingKey: widget.leadingKey,
          onDigit: _addDigit,
          onBackspace: _removeDigit,
          onClear: _clear,
        ),
        const SizedBox(height: 20),
        widget.action,
        if (widget.footer != null) ...[
          const SizedBox(height: 4),
          widget.footer!,
        ],
      ],
    );
  }
}
