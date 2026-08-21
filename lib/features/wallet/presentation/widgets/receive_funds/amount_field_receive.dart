import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/receive_conversion_widgets.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_controller.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_providers.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/btc_input_formatter.dart';
import 'package:mooze_mobile/shared/formatters/fiat_input_formatter.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class AmountFieldReceive extends ConsumerStatefulWidget {
  const AmountFieldReceive({super.key});

  @override
  ConsumerState<AmountFieldReceive> createState() => _AmountFieldReceiveState();
}

class _AmountFieldReceiveState extends ConsumerState<AmountFieldReceive> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    final initialType = ref.read(receiveConversionTypeProvider);
    _textController = TextEditingController(
      text: _readValueForType(initialType),
    );
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  String _readValueForType(ReceiveConversionType type) {
    switch (type) {
      case ReceiveConversionType.asset:
        return ref.read(receiveAssetValueProvider);
      case ReceiveConversionType.sats:
        return ref.read(receiveSatsValueProvider);
      case ReceiveConversionType.fiat:
        return ref.read(receiveFiatValueProvider);
    }
  }

  void _syncControllerFromProvider(String value) {
    if (_textController.text == value) return;
    _textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  List<TextInputFormatter> _getInputFormatters(
    Asset? selectedAsset,
    ReceiveConversionType conversionType,
  ) {
    if (conversionType == ReceiveConversionType.asset &&
        (selectedAsset == Asset.btc || selectedAsset == Asset.lbtc)) {
      return [BtcInputFormatter()];
    }
    if (conversionType == ReceiveConversionType.sats) {
      return [SatsInputFormatter()];
    }
    if (conversionType == ReceiveConversionType.fiat) {
      return [FiatInputFormatter()];
    }
    return [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Sync the controller from the active value provider whenever it
    // changes (e.g. async fiat→asset conversion completes, or the user
    // switches conversion type and the controller logic seeds the new
    // value provider). Listening here — rather than writing to the
    // controller inside build — avoids the rebuild ↔ controller-write
    // oscillation that produced the visible flicker on fiat input.
    ref.listen<ReceiveConversionType>(receiveConversionTypeProvider, (_, type) {
      _syncControllerFromProvider(_readValueForType(type));
    });
    ref.listen<String>(receiveAssetValueProvider, (_, value) {
      if (ref.read(receiveConversionTypeProvider) ==
          ReceiveConversionType.asset) {
        _syncControllerFromProvider(value);
      }
    });
    ref.listen<String>(receiveSatsValueProvider, (_, value) {
      if (ref.read(receiveConversionTypeProvider) ==
          ReceiveConversionType.sats) {
        _syncControllerFromProvider(value);
      }
    });
    ref.listen<String>(receiveFiatValueProvider, (_, value) {
      if (ref.read(receiveConversionTypeProvider) ==
          ReceiveConversionType.fiat) {
        _syncControllerFromProvider(value);
      }
    });

    final selectedNetwork = ref.watch(selectedReceiveNetworkProvider);
    final selectedAsset = ref.watch(selectedReceiveAssetProvider);
    final validationState = ref.watch(receiveValidationControllerProvider);
    final conversionType = ref.watch(receiveConversionTypeProvider);
    final isConversionLoading = ref.watch(receiveConversionLoadingProvider);
    final controller = ref.read(receiveConversionControllerProvider.notifier);

    final currentValue = controller.getCurrentValueForType(conversionType);

    final isDisabled = selectedAsset == null || selectedNetwork == null;
    final hasAmountError = validationState.amountError != null;

    final unitText = _unitFor(selectedAsset, conversionType);
    final btcAmount = double.tryParse(ref.watch(receiveAmountProvider));
    final showInfo =
        !isDisabled && currentValue.isNotEmpty && btcAmount != null;

    // Lightning was the only receive network that required an amount up
    // front; with it gone, the amount is always optional.
    final helperText =
        isDisabled
            ? t.receive_amount_helper_disabled
            : t.receive_amount_helper_optional;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    t.receive_amount_label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  ReceiveConversionOptionsRow(selectedAsset: selectedAsset),
                ],
              ),
              const SizedBox(height: 16),
              _AmountRow(
                asset: selectedAsset,
                unit: unitText,
                controller: _textController,
                focusNode: _focusNode,
                isFocused: _isFocused,
                enabled: !isDisabled,
                isError: hasAmountError,
                isLoadingConversion: isConversionLoading,
                hintText:
                    conversionType == ReceiveConversionType.fiat ? '0,00' : '0',
                inputFormatters: _getInputFormatters(
                  selectedAsset,
                  conversionType,
                ),
                onChanged: (value) {
                  if (selectedAsset == null) return;
                  final type = ref.read(receiveConversionTypeProvider);

                  String valueForController = value;
                  if (type == ReceiveConversionType.sats) {
                    final intValue = SatsInputFormatter.parseValue(value);
                    valueForController = intValue.toString();
                  } else if (type == ReceiveConversionType.fiat) {
                    final doubleValue = FiatInputFormatter.parseValue(value);
                    valueForController = doubleValue.toString();
                  }

                  controller.updateCurrentValueProvider(type, value);
                  controller.updateFinalAmountValue(
                    valueForController,
                    type,
                    selectedAsset,
                  );
                },
              ),
              _InlineError(message: validationState.amountError),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child:
                    showInfo
                        ? _InfoBlock(
                          network: selectedNetwork,
                          selectedAsset: selectedAsset,
                          btcAmount: btcAmount,
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            helperText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String _unitFor(Asset? selectedAsset, ReceiveConversionType type) {
    if (selectedAsset == null) return '';
    switch (type) {
      case ReceiveConversionType.asset:
        return selectedAsset.ticker;
      case ReceiveConversionType.sats:
        return (selectedAsset == Asset.btc || selectedAsset == Asset.lbtc)
            ? 'sats'
            : selectedAsset.ticker;
      case ReceiveConversionType.fiat:
        return ref.read(currencyControllerProvider.notifier).icon;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Amount row — Pix-style scale-on-focus layout
//
// Left column: small "Currency" eyebrow + asset icon + unit text.
// Right column: borderless, right-aligned, large amount that scales
// 1.0→1.3× when focused. Font size is derived from the available width
// at 1.3× so the value never overflows on small screens.
// ─────────────────────────────────────────────────────────────────────

class _AmountRow extends StatelessWidget {
  final Asset? asset;
  final String unit;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool enabled;
  final bool isError;
  final bool isLoadingConversion;
  final String hintText;
  final List<TextInputFormatter> inputFormatters;
  final ValueChanged<String> onChanged;

  const _AmountRow({
    required this.asset,
    required this.unit,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.enabled,
    required this.isError,
    required this.isLoadingConversion,
    required this.hintText,
    required this.inputFormatters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color valueColor;
    if (!enabled) {
      valueColor = cs.onSurface.withValues(alpha: 0.38);
    } else if (isError) {
      valueColor = cs.error;
    } else {
      valueColor = cs.onSurface;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Layout reservations.
        const leftReserved = 88.0;
        const gap = 12.0;
        // Animation/scaling.
        const maxScale = 1.2;
        // Conservative character-width ratio for w700 Inter with
        // tabular figures. Bumped from 0.6→0.7 because at w700 (vs
        // Pix's w600) digits + grouping commas can exceed 0.6 in
        // practice, which caused overflow on long sats values.
        const charRatio = 0.7;
        // 12px floor handles the 16-digit cap (e.g. sats up to
        // "1.111.111.111.111.111" = 21 visible chars with separators)
        // on narrow screens without resorting to clipping.
        const minFontSize = 12.0;
        const maxFontSize = 30.0;

        // Account for system text scaling (accessibility) on top of
        // our AnimatedScale so the two don't compound into overflow.
        final textScaler = MediaQuery.textScalerOf(context);
        final scaleFactor = textScaler.scale(1.0).clamp(1.0, 3.0);

        // Size the font from the CURRENT text length, not a fixed
        // worst-case. Short values stay big (up to maxFontSize), long
        // values shrink down to minFontSize. effectiveChars is clamped
        // so a 20-character sats value still gets a font calculation,
        // not a divide-by-tiny.
        final currentText =
            controller.text.isEmpty ? hintText : controller.text;
        final effectiveChars = currentText.length.clamp(1, 20).toDouble();

        final availableRight = (constraints.maxWidth - leftReserved - gap)
            .clamp(60.0, double.infinity);
        final naturalFontSize =
            availableRight /
            (maxScale * scaleFactor * effectiveChars * charRatio);
        final fontSize = naturalFontSize.clamp(minFontSize, maxFontSize);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: leftReserved,
              child: _UnitColumn(
                asset: asset,
                unit: unit,
                enabled: enabled,
                isLoadingConversion: isLoadingConversion,
              ),
            ),
            const SizedBox(width: gap),
            Expanded(
              // ClipRect is a safety net: even if the font calc is off
              // (variant char widths, a font without tabular figures,
              // an unexpectedly large text scaler), scaled overflow
              // gets clipped at the right column's left edge instead
              // of rendering on top of the unit icon.
              child: ClipRect(
                child: AnimatedScale(
                  scale: isFocused ? maxScale : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.centerRight,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    maxLines: 1,
                    scrollPhysics: const NeverScrollableScrollPhysics(),
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: inputFormatters,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.22),
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                      ),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: onChanged,
                    onSubmitted: (_) => focusNode.unfocus(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UnitColumn extends StatelessWidget {
  final Asset? asset;
  final String unit;
  final bool enabled;
  final bool isLoadingConversion;

  const _UnitColumn({
    required this.asset,
    required this.unit,
    required this.enabled,
    required this.isLoadingConversion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.colors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (asset != null) ...[
              Opacity(
                opacity: enabled ? 1 : 0.5,
                child: SvgPicture.asset(
                  asset!.iconPath,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (isLoadingConversion)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.4,
                  color: muted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          unit,
          style: theme.textTheme.labelLarge?.copyWith(
            color:
                enabled
                    ? theme.colorScheme.onSurface
                    : muted.withValues(alpha: 0.7),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // Text(
        //   asset?.name ?? '',
        //   style: theme.textTheme.labelSmall?.copyWith(
        //     color: muted,
        //     letterSpacing: 0.2,
        //   ),
        //   maxLines: 1,
        //   overflow: TextOverflow.ellipsis,
        // ),
      ],
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
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 14,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
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

class _InfoBlock extends StatelessWidget {
  final NetworkType network;
  final Asset selectedAsset;
  final double btcAmount;

  const _InfoBlock({
    required this.network,
    required this.selectedAsset,
    required this.btcAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor =
        isDark
            ? theme.colorScheme.outlineVariant.withValues(alpha: 0.25)
            : theme.colorScheme.outline.withValues(alpha: 0.25);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Divider(height: 1, thickness: 1, color: dividerColor),
        const SizedBox(height: 14),
        ReceiveConversionPreview(
          selectedAsset: selectedAsset,
          assetAmount: btcAmount,
        ),
        const SizedBox(height: 12),
        _ValidationChip(network: network, btcAmount: btcAmount),
      ],
    );
  }
}

class _ValidationChip extends ConsumerWidget {
  final NetworkType network;
  final double btcAmount;

  const _ValidationChip({required this.network, required this.btcAmount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final positive = context.colors.positiveColor;

    if (network == NetworkType.bitcoin) {
      return _Chip(
        icon: Icons.check_circle_outline_rounded,
        text: t.receive_bitcoin_valid,
        color: positive,
      );
    } else if (network == NetworkType.liquid) {
      return _Chip(
        icon: Icons.check_circle_outline_rounded,
        text: t.receive_liquid_valid,
        color: positive,
      );
    }
    return const SizedBox.shrink();
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Chip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
