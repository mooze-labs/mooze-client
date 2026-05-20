import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/send_funds/address_controller_provider.dart';
import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/detected_amount_provider.dart';
import '../../providers/send_funds/network_detection_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';

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
      if (currentAddress.isNotEmpty && controller.text != currentAddress) {
        controller.text = currentAddress;
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

  void _autoSwitchAssetBasedOnNetwork(String address) {
    if (address.isEmpty) return;

    final detectedResult = ref.read(detectedAmountProvider);
    if (detectedResult.asset != null) {
      ref.read(selectedAssetProvider.notifier).state = detectedResult.asset!;
      return;
    }

    final networkType = NetworkDetectionService.detectNetworkType(address);
    final currentAsset = ref.read(selectedAssetProvider);

    Asset? newAsset;
    switch (networkType) {
      case NetworkType.bitcoin:
        if (currentAsset != Asset.btc) newAsset = Asset.btc;
        break;
      case NetworkType.lightning:
      case NetworkType.liquid:
      case NetworkType.unknown:
        break;
    }

    if (newAsset != null) {
      ref.read(selectedAssetProvider.notifier).state = newAsset;
    }
  }

  void _applyAddress(String address) {
    final trimmed = address.trim();
    ref.read(addressStateProvider.notifier).state = trimmed;
    _autoSwitchAssetBasedOnNetwork(trimmed);
    ref.invalidate(detectedAmountProvider);
    ref.read(sendValidationControllerProvider.notifier).validateTransaction();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).wallet_send_address_paste_empty,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.selectionClick();
    final controller = ref.read(addressControllerProvider);
    controller.text = text;
    controller.selection = TextSelection.collapsed(offset: text.length);
    _applyAddress(text);
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.wallet_send_address_label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: TextField(
            controller: controller,
            focusNode: _focusNode,
            // Monospace once filled — addresses are character-by-character
            // verified, and fixed-width digits/letters help the user
            // confirm what they're sending to.
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: hasText ? 'monospace' : null,
              fontSize: hasText ? 13.5 : null,
              letterSpacing: hasText ? 0.2 : 0,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: t.wallet_send_address_hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.textTertiary,
              ),
              suffixIcon: _SuffixActions(
                hasText: hasText,
                onPaste: _pasteFromClipboard,
                onClear: _clearAddress,
                onScan: () => _openQRScanner(context),
                pasteTooltip: t.wallet_send_address_paste,
                clearTooltip: t.wallet_send_address_clear,
                scanTooltip: t.wallet_send_address_scan_qr,
              ),
              border: _border(context),
              enabledBorder: _border(context),
              focusedBorder: _border(context, focused: true),
              errorBorder: _border(context, error: true),
              focusedErrorBorder: _border(context, focused: true, error: true),
              disabledBorder: _border(context),
              filled: true,
              fillColor: cs.onSurface.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            maxLines: 3,
            minLines: 1,
            onChanged: _applyAddress,
          ),
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
    final cs = Theme.of(context).colorScheme;
    Color color;
    double width = 1;
    if (error) {
      color = cs.error;
      width = focused ? 1.5 : 1;
    } else if (focused) {
      color = cs.primary;
      width = 1.5;
    } else {
      color = cs.onSurface.withValues(alpha: 0.08);
    }
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder:
                (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
            child:
                hasText
                    ? _SuffixIconButton(
                      key: const ValueKey('clear'),
                      icon: Icons.close_rounded,
                      tooltip: clearTooltip,
                      onTap: onClear,
                    )
                    : _SuffixIconButton(
                      key: const ValueKey('paste'),
                      icon: Icons.content_paste_rounded,
                      tooltip: pasteTooltip,
                      onTap: onPaste,
                    ),
          ),
          const SizedBox(width: 2),
          _SuffixIconButton(
            icon: Icons.qr_code_scanner_rounded,
            tooltip: scanTooltip,
            onTap: onScan,
            tinted: true,
          ),
        ],
      ),
    );
  }
}

class _SuffixIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  final bool tinted;

  const _SuffixIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.tinted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = tinted ? cs.primary.withValues(alpha: 0.12) : Colors.transparent;
    final fg = tinted ? cs.primary : context.colors.textSecondary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: fg),
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String? message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child:
          (message == null || message!.isEmpty)
              ? const SizedBox.shrink()
              : Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 14,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        message!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
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
