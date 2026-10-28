import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
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
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The optional amount of the receive request.
///
/// The amount is the hero of the step: large digits with tabular figures
/// on the page, the unit muted next to them, and one line below that
/// follows the focus. The other units show as one quiet line.
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
    final helperText = isDisabled
        ? t.receive_amount_helper_disabled
        : t.receive_amount_helper_optional;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The label and the unit switch wrap to two lines with large
        // text on a narrow screen.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Semantics(
              header: true,
              child: Text(
                t.receive_amount_label,
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ReceiveConversionOptionsRow(selectedAsset: selectedAsset),
          ],
        ),
        const SizedBox(height: 12),
        _HeroAmount(
          unit: unitText,
          unitLeading: conversionType == ReceiveConversionType.fiat,
          controller: _textController,
          focusNode: _focusNode,
          enabled: !isDisabled,
          isError: hasAmountError,
          isLoadingConversion: isConversionLoading,
          hintText: conversionType == ReceiveConversionType.fiat ? '0,00' : '0',
          inputFormatters: _getInputFormatters(selectedAsset, conversionType),
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
        const SizedBox(height: 8),
        _FocusLine(focused: _isFocused, isError: hasAmountError),
        _InlineError(message: validationState.amountError),
        const SizedBox(height: 10),
        SizeFadeSwitcher(
          alignment: AlignmentDirectional.topStart,
          child: showInfo
              ? _InfoBlock(
                  key: const ValueKey('info'),
                  network: selectedNetwork,
                  selectedAsset: selectedAsset,
                  btcAmount: btcAmount,
                )
              : Text(
                  helperText,
                  key: const ValueKey('helper'),
                  style: context.textTheme.bodySmall?.copyWith(
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
// Hero amount: borderless digits on the page with the muted unit next
// to them. A currency symbol comes before the digits, as in "R$ 150,00".
// A crypto unit comes after them, as in "0.0015 BTC". The field is as
// wide as its text, so the unit stays close to the digits. The font
// shrinks to fit the width, also with large system text, so a long sats
// value never overflows.
// ─────────────────────────────────────────────────────────────────────

class _HeroAmount extends StatelessWidget {
  final String unit;
  final bool unitLeading;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isError;
  final bool isLoadingConversion;
  final String hintText;
  final List<TextInputFormatter> inputFormatters;
  final ValueChanged<String> onChanged;

  const _HeroAmount({
    required this.unit,
    required this.unitLeading,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isError,
    required this.isLoadingConversion,
    required this.hintText,
    required this.inputFormatters,
    required this.onChanged,
  });

  static const double _maxFontSize = 40;

  /// Smallest rendered digit size, after the system text scale.
  static const double _minRenderedSize = 18;
  static const double _unitGap = 6;

  /// Room for the caret after the last digit.
  static const double _caretSlack = 4;

  static double _measure(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    // The floor is a rendered size, so large system text can shrink the
    // logical size further and still fit a long value.
    final minFontSize =
        _minRenderedSize *
        _minRenderedSize /
        textScaler.scale(_minRenderedSize);

    final Color valueColor;
    if (!enabled) {
      valueColor = cs.onSurface.withValues(alpha: 0.38);
    } else if (isError) {
      valueColor = context.colors.negativeColor;
    } else {
      valueColor = context.colors.textPrimary;
    }

    // The field merges its style into titleMedium, so the measure does too.
    final baseStyle = context.textTheme.titleMedium!.merge(
      context.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final unitStyle = context.textTheme.titleMedium!.merge(
      context.textTheme.titleLarge?.copyWith(
        color: enabled
            ? context.colors.textSecondary
            : context.colors.textSecondary.withValues(alpha: 0.5),
        fontWeight: FontWeight.w500,
      ),
    );

    return GestureDetector(
      // A tap anywhere on the hero line opens the keyboard, not only a
      // tap on the digits.
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? focusNode.requestFocus : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final shown = value.text.isEmpty ? hintText : value.text;
                final reserved =
                    _measure(unit, unitStyle, textScaler) +
                    _unitGap +
                    (isLoadingConversion ? 20 : 0) +
                    _caretSlack;
                final available = math.max(
                  48.0,
                  constraints.maxWidth - reserved,
                );

                var fontSize = _maxFontSize;
                var width = _measure(
                  shown,
                  baseStyle.copyWith(fontSize: fontSize),
                  textScaler,
                );
                if (width > available) {
                  fontSize = math.max(
                    minFontSize,
                    fontSize * available / width,
                  );
                  width = _measure(
                    shown,
                    baseStyle.copyWith(fontSize: fontSize),
                    textScaler,
                  );
                }
                final fieldWidth = math.min(available, width + _caretSlack);
                final style = baseStyle.copyWith(
                  fontSize: fontSize,
                  color: valueColor,
                );

                final field = SizedBox(
                  width: fieldWidth,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    maxLines: 1,
                    scrollPhysics: const NeverScrollableScrollPhysics(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: inputFormatters,
                    cursorColor: context.colors.primaryColor,
                    style: style,
                    decoration: InputDecoration(
                      // The app theme fills its fields. The amount sits on
                      // the page, with the line below as its frame.
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      hintText: hintText,
                      hintStyle: style.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.22),
                      ),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: onChanged,
                    onSubmitted: (_) => focusNode.unfocus(),
                  ),
                );
                final unitText = Flexible(
                  child: Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: unitStyle,
                  ),
                );
                final spinner = SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.4,
                    color: context.colors.textSecondary,
                  ),
                );

                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (unitLeading) ...[
                        unitText,
                        const SizedBox(width: _unitGap),
                        field,
                      ] else ...[
                        field,
                        const SizedBox(width: _unitGap),
                        unitText,
                      ],
                      if (isLoadingConversion) ...[
                        const SizedBox(width: 8),
                        // The spinner has no baseline. Baseline puts its
                        // bottom edge on the text baseline.
                        Baseline(
                          baseline: 12,
                          baselineType: TextBaseline.alphabetic,
                          child: spinner,
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The line below the digits. It is thin at rest, turns brand pink and
/// thicker with the focus, and turns to the error color with an error.
class _FocusLine extends StatelessWidget {
  final bool focused;
  final bool isError;

  const _FocusLine({required this.focused, required this.isError});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.of(context, Motion.durationFast),
      curve: Motion.curveMove,
      height: focused || isError ? 2 : 1,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        color: isError
            ? context.colors.negativeColor
            : focused
            ? context.colors.primaryColor
            // The outline shows on the page in both themes.
            : context.colorScheme.outline,
      ),
    );
  }
}

/// The amount error: an alert icon, the message, and the error color.
class _InlineError extends StatelessWidget {
  final String? message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final hasMessage = message != null && message!.isNotEmpty;
    final color = context.colors.negativeColor;
    return SizeFadeSwitcher(
      alignment: AlignmentDirectional.topStart,
      child: !hasMessage
          ? const SizedBox(key: ValueKey('none'), width: double.infinity)
          : Padding(
              key: ValueKey(message),
              padding: const EdgeInsets.only(top: 10),
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

/// The conversions and the network check, shown once an amount exists.
class _InfoBlock extends StatelessWidget {
  final NetworkType network;
  final Asset selectedAsset;
  final double btcAmount;

  const _InfoBlock({
    super.key,
    required this.network,
    required this.selectedAsset,
    required this.btcAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceiveConversionPreview(
          selectedAsset: selectedAsset,
          assetAmount: btcAmount,
        ),
        const SizedBox(height: 8),
        _ValidationLine(network: network),
      ],
    );
  }
}

/// A check icon and a short text in the positive color.
class _ValidationLine extends StatelessWidget {
  final NetworkType network;

  const _ValidationLine({required this.network});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = switch (network) {
      NetworkType.bitcoin => t.receive_bitcoin_valid,
      NetworkType.liquid => t.receive_liquid_valid,
      NetworkType.unknown => null,
    };
    if (text == null) return const SizedBox.shrink();

    final positive = context.colors.positiveColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: PixIcon(PixIcons.success, size: 15, color: positive),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: positive,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
