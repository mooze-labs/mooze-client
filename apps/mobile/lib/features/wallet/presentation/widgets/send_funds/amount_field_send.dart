import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/amount_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/bitcoin_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_network_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/send_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/send_conversion_widgets.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/btc_input_formatter.dart';
import 'package:mooze_mobile/shared/formatters/fiat_input_formatter.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'send_flow_parts.dart';

enum SendConversionType { asset, sats, fiat }

extension SendConversionTypeExtension on SendConversionType {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context);
    switch (this) {
      case SendConversionType.asset:
        return t.wallet_send_conversion_asset;
      case SendConversionType.sats:
        return t.wallet_send_conversion_sats;
      case SendConversionType.fiat:
        return t.wallet_send_conversion_fiat;
    }
  }

  IconData get icon {
    switch (this) {
      case SendConversionType.asset:
        return Icons.currency_bitcoin;
      case SendConversionType.sats:
        return Icons.bolt;
      case SendConversionType.fiat:
        return Icons.attach_money;
    }
  }
}

final sendConversionTypeProvider = StateProvider<SendConversionType>((ref) {
  return SendConversionType.fiat;
});

/// The amount step of the send form, drawn as the hero of the screen.
///
/// The digits are large, with tabular figures, and the unit is muted next
/// to them. A line below the digits follows the focus and turns to the
/// error color with an amount error. Below it, a quiet line shows the
/// amount in the other units, and "MAX" sends the whole balance.
class AmountFieldSend extends ConsumerStatefulWidget {
  const AmountFieldSend({super.key});

  @override
  ConsumerState<AmountFieldSend> createState() => _AmountFieldSendState();
}

class _AmountFieldSendState extends ConsumerState<AmountFieldSend> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _isFocused = false;
  int? _lastPushedSats;
  bool _suspendOnChanged = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode()..addListener(_onFocusChange);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resyncFromCanonical();
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
    _textController.dispose();
    super.dispose();
  }

  String _formatDisplay({
    required int sats,
    required SendConversionType mode,
    required double? price,
  }) {
    switch (mode) {
      case SendConversionType.sats:
        return SatsInputFormatter.formatValue(sats);
      case SendConversionType.asset:
        return BtcInputFormatter.formatValue(sats / 100000000);
      case SendConversionType.fiat:
        if (price == null || price <= 0) return '';
        return FiatInputFormatter.formatValue((sats / 100000000) * price);
    }
  }

  int _parseToSats({
    required String value,
    required SendConversionType mode,
    required double? price,
  }) {
    if (value.isEmpty) return 0;
    switch (mode) {
      case SendConversionType.sats:
        return SatsInputFormatter.parseValue(value);
      case SendConversionType.asset:
        final assetValue = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
        if (assetValue <= 0) return 0;
        return (assetValue * 100000000).toInt();
      case SendConversionType.fiat:
        if (price == null || price <= 0) return 0;
        final fiat = FiatInputFormatter.parseValue(value);
        if (fiat <= 0) return 0;
        return ((fiat / price) * 100000000).toInt();
    }
  }

  List<TextInputFormatter> _inputFormattersFor(SendConversionType type) {
    switch (type) {
      case SendConversionType.asset:
        return [BtcInputFormatter()];
      case SendConversionType.sats:
        return [SatsInputFormatter()];
      case SendConversionType.fiat:
        return [FiatInputFormatter()];
    }
  }

  double? _priceFor(Asset asset) {
    final btcPrice = ref.read(bitcoinPriceProvider).value;
    final assetPrice = ref.read(selectedAssetPriceProvider).value;
    return (asset == Asset.btc || asset == Asset.lbtc) ? btcPrice : assetPrice;
  }

  void _resyncFromCanonical() {
    if (!mounted) return;
    final sats = ref.read(amountStateProvider);
    final mode = ref.read(sendConversionTypeProvider);
    final asset = ref.read(selectedAssetProvider);
    final price = _priceFor(asset);

    final display = _formatDisplay(sats: sats, mode: mode, price: price);
    if (_textController.text != display) {
      _suspendOnChanged = true;
      _textController.text = display;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: display.length),
      );
      _suspendOnChanged = false;
    }
    _lastPushedSats = sats;
  }

  void _scheduleResync() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resyncFromCanonical();
    });
  }

  void _onUserInput(String value) {
    if (_suspendOnChanged) return;

    final mode = ref.read(sendConversionTypeProvider);
    final asset = ref.read(selectedAssetProvider);
    final price = _priceFor(asset);

    final sats = _parseToSats(value: value, mode: mode, price: price);

    _lastPushedSats = sats;
    ref.read(amountStateProvider.notifier).state = sats;

    if (ref.read(maxSendRequestedProvider)) {
      ref.read(maxSendRequestedProvider.notifier).state = false;
    }
  }

  void _setMaxAmount(Asset asset, int satsAmount) {
    _lastPushedSats = null;
    ref.read(amountStateProvider.notifier).state = satsAmount;
    ref.read(maxSendRequestedProvider.notifier).state = true;

    final mode = ref.read(sendConversionTypeProvider);
    if (mode == SendConversionType.fiat && _priceFor(asset) == null) {
      ref.read(sendConversionTypeProvider.notifier).state =
          SendConversionType.sats;
    }
    _scheduleResync();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    ref.listen<int>(amountStateProvider, (_, next) {
      if (next != _lastPushedSats) _scheduleResync();
    });
    ref.listen<SendConversionType>(
      sendConversionTypeProvider,
      (_, _) => _scheduleResync(),
    );
    ref.listen<Asset>(selectedAssetProvider, (_, _) => _scheduleResync());
    ref.listen(bitcoinPriceProvider, (_, _) => _scheduleResync());
    ref.listen(selectedAssetPriceProvider, (_, _) => _scheduleResync());

    final selectedNetwork = ref.watch(selectedNetworkProvider);
    final selectedAsset = ref.watch(selectedAssetProvider);
    final validationState = ref.watch(sendValidationControllerProvider);
    final conversionType = ref.watch(sendConversionTypeProvider);
    final amountInSats = ref.watch(amountStateProvider);
    final btcAmount = amountInSats / 100000000;

    SendValidationError? amountError;
    for (final error in validationState.errors) {
      final cat = error.category;
      if (cat == SendValidationErrorCategory.amount ||
          cat == SendValidationErrorCategory.limits ||
          cat == SendValidationErrorCategory.balance) {
        amountError = error;
        break;
      }
    }

    final unitText = _unitFor(selectedAsset, conversionType);
    final showInfo = amountInSats > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The unit choice moves below the label when both do not fit on one
        // line, for example with large text.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            SendSectionLabel(t.wallet_send_amount_label, active: _isFocused),
            SendConversionOptionsRow(selectedAsset: selectedAsset),
          ],
        ),
        const SizedBox(height: 14),
        _AmountRow(
          unit: unitText,
          unitFirst: conversionType == SendConversionType.fiat,
          controller: _textController,
          focusNode: _focusNode,
          isError: amountError != null,
          inputFormatters: _inputFormattersFor(conversionType),
          onChanged: _onUserInput,
        ),
        const SizedBox(height: 10),
        _FocusLine(focused: _isFocused, isError: amountError != null),
        _InlineError(message: amountError?.localize(context)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizeFadeSwitcher(
                alignment: AlignmentDirectional.centerStart,
                child: showInfo
                    ? _InfoBlock(
                        key: const ValueKey('info'),
                        network: selectedNetwork,
                        selectedAsset: selectedAsset,
                        btcAmount: btcAmount,
                      )
                    : const SizedBox(
                        key: ValueKey('none'),
                        width: double.infinity,
                      ),
              ),
            ),
            const _MaxButton(),
          ],
        ),
      ],
    );
  }

  String _unitFor(Asset? selectedAsset, SendConversionType type) {
    if (selectedAsset == null) return '';
    switch (type) {
      case SendConversionType.asset:
        return selectedAsset.ticker;
      case SendConversionType.sats:
        return (selectedAsset == Asset.btc || selectedAsset == Asset.lbtc)
            ? 'sats'
            : selectedAsset.ticker;
      case SendConversionType.fiat:
        return ref.read(currencyControllerProvider.notifier).icon;
    }
  }
}

/// "MAX" as a small text action. It shows only when the asset has a
/// balance.
///
/// While the whole balance is selected, the label turns brand pink and
/// gets a check, so the state never depends on color alone.
class _MaxButton extends ConsumerWidget {
  const _MaxButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.watch(selectedAssetProvider);
    final selectedAssetBalance = ref.watch(selectedAssetBalanceRawProvider);
    final isActive = ref.watch(maxSendRequestedProvider);
    final state = context.findAncestorStateOfType<_AmountFieldSendState>();

    return selectedAssetBalance.when(
      data: (data) => data.fold((_) => const SizedBox.shrink(), (amount) {
        if (amount <= BigInt.zero || state == null) {
          return const SizedBox.shrink();
        }
        return _MaxAction(
          label: AppLocalizations.of(context).common_max,
          isActive: isActive,
          onTap: () => state._setMaxAmount(selectedAsset, amount.toInt()),
        );
      }),
      error: (_, _) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}

class _MaxAction extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _MaxAction({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? context.colors.primaryColor
        : context.colors.textPrimary;
    return Semantics(
      selected: isActive,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(48, 40),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              PixIcon(PixIcons.check, size: 16, color: color),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// The digits and the muted unit, on one baseline.
///
/// The digits shrink as the text grows, so a long amount stays on one line.
/// A fiat unit comes before the digits, a crypto unit after them.
class _AmountRow extends StatelessWidget {
  final String unit;
  final bool unitFirst;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isError;
  final List<TextInputFormatter> inputFormatters;
  final ValueChanged<String> onChanged;

  const _AmountRow({
    required this.unit,
    required this.unitFirst,
    required this.controller,
    required this.focusNode,
    required this.isError,
    required this.inputFormatters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = isError
        ? context.colors.negativeColor
        : context.colors.textPrimary;
    final unitStyle = context.textTheme.titleLarge?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w500,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const unitReserve = 80.0;
        const charRatio = 0.62;
        const minFontSize = 18.0;
        const maxFontSize = 40.0;

        final textScaler = MediaQuery.textScalerOf(context);
        final scaleFactor = textScaler.scale(1.0).clamp(1.0, 3.0);

        final currentText = controller.text.isEmpty ? '0' : controller.text;
        final effectiveChars = currentText.length.clamp(4, 24).toDouble();

        final available = (constraints.maxWidth - unitReserve).clamp(
          60.0,
          double.infinity,
        );
        final fontSize =
            (available / (scaleFactor * effectiveChars * charRatio)).clamp(
              minFontSize,
              maxFontSize,
            );

        final digitsStyle = context.textTheme.headlineLarge?.copyWith(
          color: valueColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          fontFeatures: sendTabularFigures,
        );

        final unitText = Text(
          unit,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: unitStyle,
        );

        // A tap on the unit also opens the keyboard.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: focusNode.requestFocus,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (unitFirst) ...[unitText, const SizedBox(width: 8)],
              Flexible(
                // The field takes the width of its text, so the unit sits
                // right after the digits.
                child: IntrinsicWidth(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLines: 1,
                    scrollPhysics: const NeverScrollableScrollPhysics(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: inputFormatters,
                    cursorColor: context.colors.primaryColor,
                    style: digitsStyle,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      hintText: '0',
                      hintStyle: digitsStyle?.copyWith(
                        color: context.colors.textTertiary,
                      ),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: onChanged,
                    onSubmitted: (_) => focusNode.unfocus(),
                  ),
                ),
              ),
              if (!unitFirst) ...[
                const SizedBox(width: 8),
                Flexible(flex: 0, child: unitText),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The line below the digits. It follows the focus and the error state.
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
            // The light outline variant has the page color. The outline
            // shows in both themes.
            : context.colorScheme.outline,
      ),
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

/// The amount in the other units, and a check when the amount is valid.
class _InfoBlock extends StatelessWidget {
  final Blockchain network;
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
      mainAxisSize: MainAxisSize.min,
      children: [
        SendConversionPreview(
          selectedAsset: selectedAsset,
          assetAmount: btcAmount,
        ),
        _ValidationChip(network: network),
      ],
    );
  }
}

class _ValidationChip extends ConsumerWidget {
  final Blockchain network;
  const _ValidationChip({required this.network});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);

    final validationState = ref.watch(sendValidationControllerProvider);
    final hasAmountInvalidatingError = validationState.errors.any((e) {
      final cat = e.category;
      return cat == SendValidationErrorCategory.amount ||
          cat == SendValidationErrorCategory.limits ||
          cat == SendValidationErrorCategory.balance;
    });
    if (hasAmountInvalidatingError) return const SizedBox.shrink();

    if (network == Blockchain.liquid || network == Blockchain.bitcoin) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixIcon(
              PixIcons.success,
              size: 14,
              color: context.colors.positiveColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                t.wallet_send_amount_valid,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
