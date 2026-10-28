import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/send_funds/address_controller_provider.dart';
import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/detected_amount_provider.dart';
import '../../providers/send_funds/payment_request_applier.dart';
import '../../providers/send_funds/send_validation_controller.dart';
import 'send_flow_parts.dart';

/// The destination address field of the send form.
///
/// The field is a glass lens with two icon buttons at its end: paste (or
/// clear, when the field has text) and scan. The border turns brand pink
/// with the focus and turns to the error color with an address error. The
/// error shows below the field with an alert icon.
class AddressField extends ConsumerStatefulWidget {
  const AddressField({super.key});

  @override
  ConsumerState<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends ConsumerState<AddressField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentAddress = ref.read(addressStateProvider);
      final controller = ref.read(addressControllerProvider);
      final display = PaymentRequestApplier.displayAddress(currentAddress);
      if (currentAddress.isNotEmpty && controller.text != display) {
        controller.text = display;
      }
    });
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _applyAddress(String address) {
    final trimmed = address.trim();
    ref.read(addressStateProvider.notifier).state = trimmed;
    PaymentRequestApplier.autoSwitchAsset(ref, trimmed);
    ref.invalidate(detectedAmountProvider);
    ref.read(sendValidationControllerProvider.notifier).validateTransaction();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      AppSnackBar.info(
        context,
        AppLocalizations.of(context).wallet_send_address_paste_empty,
      );
      return;
    }
    HapticFeedback.selectionClick();
    final result = PaymentRequestApplier.apply(ref, text);
    if (!result.isValid && mounted) {
      AppSnackBar.error(context, result.localize(context));
    }
  }

  void _clearAddress() {
    HapticFeedback.selectionClick();
    ref.read(addressControllerProvider).clear();
    _applyAddress('');
  }

  void _openQRScanner(BuildContext context) {
    context.push('/send-funds/scanner');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final controller = ref.watch(addressControllerProvider);
    final validationState = ref.watch(sendValidationControllerProvider);

    final addressState = ref.watch(addressStateProvider);
    final hasText = addressState.isNotEmpty || controller.text.isNotEmpty;

    SendValidationError? addressError;
    for (final error in validationState.errors) {
      if (error.category == SendValidationErrorCategory.address ||
          error.category == SendValidationErrorCategory.network) {
        addressError = error;
        break;
      }
    }
    final errorMessage = addressError?.localize(context);
    final hasError = errorMessage != null && errorMessage.isNotEmpty;

    final textStyle = context.textTheme.bodyLarge?.copyWith(
      color: context.colors.textPrimary,
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The label brightens while the field has the focus.
        SendSectionLabel(t.wallet_send_address_label, active: _isFocused),
        const SizedBox(height: 10),
        TextField(
          autofocus: true,
          controller: controller,
          focusNode: _focusNode,
          autocorrect: false,
          enableSuggestions: false,
          cursorColor: context.colors.primaryColor,
          // Monospace once filled. Users check an address character by
          // character, and fixed-width glyphs make that easier.
          style: textStyle?.copyWith(
            fontFamily: hasText ? 'monospace' : null,
            fontSize: hasText ? 14 : null,
            letterSpacing: hasText ? 0.2 : 0,
          ),
          decoration: InputDecoration(
            hintText: t.wallet_send_address_hint,
            hintStyle: textStyle?.copyWith(color: context.colors.textTertiary),
            suffixIcon: _SuffixActions(
              hasText: hasText,
              onPaste: _pasteFromClipboard,
              onClear: _clearAddress,
              onScan: () => _openQRScanner(context),
              pasteTooltip: t.wallet_send_address_paste,
              clearTooltip: t.wallet_send_address_clear,
              scanTooltip: t.wallet_send_address_scan_qr,
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            border: _border(context),
            enabledBorder: _border(context, error: hasError),
            focusedBorder: _border(context, focused: true, error: hasError),
            disabledBorder: _border(context),
            filled: true,
            fillColor: GlassStyle.of(context).lensFill,
            contentPadding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
          ),
          maxLines: 3,
          minLines: 1,
          onChanged: _applyAddress,
        ),
        _InlineError(message: errorMessage),
      ],
    );
  }

  OutlineInputBorder _border(
    BuildContext context, {
    bool focused = false,
    bool error = false,
  }) {
    final Color color;
    final double width;
    if (error) {
      color = context.colors.negativeColor;
      width = focused ? 2 : 1.5;
    } else if (focused) {
      color = context.colors.primaryColor;
      width = 2;
    } else {
      color = AppSurfaces.hairline(context);
      width = 1;
    }
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Paste or clear, then scan, at the end of the field.
///
/// Each button has a 48 pt touch target and a tooltip, which is also its
/// label for screen readers.
class _SuffixActions extends StatelessWidget {
  final bool hasText;
  final VoidCallback onPaste;
  final VoidCallback onClear;
  final VoidCallback onScan;
  final String pasteTooltip;
  final String clearTooltip;
  final String scanTooltip;

  const _SuffixActions({
    required this.hasText,
    required this.onPaste,
    required this.onClear,
    required this.onScan,
    required this.pasteTooltip,
    required this.clearTooltip,
    required this.scanTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, Motion.durationFast);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: duration,
            switchInCurve: Motion.curveEnter,
            switchOutCurve: Motion.curveExit,
            child: hasText
                ? _SuffixIconButton(
                    key: const ValueKey('clear'),
                    icon: PixIcons.close,
                    tooltip: clearTooltip,
                    onTap: onClear,
                    color: context.colors.textTertiary,
                  )
                : _SuffixIconButton(
                    key: const ValueKey('paste'),
                    icon: PixIcons.paste,
                    tooltip: pasteTooltip,
                    onTap: onPaste,
                    color: context.colors.textSecondary,
                  ),
          ),
          _SuffixIconButton(
            icon: PixIcons.scan,
            tooltip: scanTooltip,
            onTap: onScan,
            color: context.colors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _SuffixIconButton extends StatelessWidget {
  final PixIconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _SuffixIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: PixIcon(icon, size: 20, color: color),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String? message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final show = message != null && message!.isNotEmpty;
    final color = context.colors.negativeColor;
    return SizeFadeSwitcher(
      alignment: AlignmentDirectional.topStart,
      child: !show
          ? const SizedBox(key: ValueKey('none'), width: double.infinity)
          : Padding(
              key: ValueKey(message),
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: PixIcon(PixIcons.error, size: 15, color: color),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      message!,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
