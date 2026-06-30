import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:mooze_mobile/themes/theme_context_x.dart';

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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

    return Container(
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
                t.wallet_send_amount_label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const _MaxButton(),
              const SizedBox(width: 8),
              SendConversionOptionsRow(selectedAsset: selectedAsset),
            ],
          ),
          const SizedBox(height: 16),
          _AmountRow(
            asset: selectedAsset,
            unit: unitText,
            controller: _textController,
            focusNode: _focusNode,
            isFocused: _isFocused,
            isError: amountError != null,
            inputFormatters: _inputFormattersFor(conversionType),
            onChanged: _onUserInput,
          ),
          _InlineError(message: amountError?.localize(context)),
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
                      amountInSats: amountInSats,
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
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

class _MaxButton extends ConsumerWidget {
  const _MaxButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.watch(selectedAssetProvider);
    final selectedAssetBalance = ref.watch(selectedAssetBalanceRawProvider);
    final isActive = ref.watch(maxSendRequestedProvider);
    final state = context.findAncestorStateOfType<_AmountFieldSendState>();

    return selectedAssetBalance.when(
      data:
          (data) => data.fold((_) => const SizedBox.shrink(), (amount) {
            if (amount <= BigInt.zero || state == null) {
              return const SizedBox.shrink();
            }
            return _ChipAction(
              label: 'MAX',
              isActive: isActive,
              onTap: () => state._setMaxAmount(selectedAsset, amount.toInt()),
            );
          }),
      error: (_, _) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}

class _ChipAction extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ChipAction({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isActive ? cs.primary : cs.primary.withValues(alpha: 0.10);
    final fg = isActive ? cs.onPrimary : cs.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final Asset? asset;
  final String unit;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool isError;
  final List<TextInputFormatter> inputFormatters;
  final ValueChanged<String> onChanged;

  const _AmountRow({
    required this.asset,
    required this.unit,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.isError,
    required this.inputFormatters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color valueColor = isError ? cs.error : cs.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        const leftReserved = 88.0;
        const gap = 12.0;
        const maxScale = 1.2;
        const charRatio = 0.7;
        const minFontSize = 12.0;
        const maxFontSize = 30.0;

        final textScaler = MediaQuery.textScalerOf(context);
        final scaleFactor = textScaler.scale(1.0).clamp(1.0, 3.0);

        final currentText = controller.text.isEmpty ? '0' : controller.text;
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
              child: _UnitColumn(asset: asset, unit: unit),
            ),
            const SizedBox(width: gap),
            Expanded(
              child: ClipRect(
                child: AnimatedScale(
                  scale: isFocused ? maxScale : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.centerRight,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
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
                      hintText: '0',
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

  const _UnitColumn({required this.asset, required this.unit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.colors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (asset != null)
          SvgPicture.asset(
            asset!.iconPath,
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          ),
        const SizedBox(height: 8),
        Text(
          unit,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
  final Blockchain network;
  final Asset selectedAsset;
  final double btcAmount;
  final int amountInSats;

  const _InfoBlock({
    required this.network,
    required this.selectedAsset,
    required this.btcAmount,
    required this.amountInSats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor =
        isDark
            ? theme.colorScheme.outlineVariant.withValues(alpha: 0.25)
            : theme.colorScheme.outline.withValues(alpha: 0.25);
    final t = AppLocalizations.of(context);
    final isBtcLike = selectedAsset == Asset.btc || selectedAsset == Asset.lbtc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Divider(height: 1, thickness: 1, color: dividerColor),
        const SizedBox(height: 14),
        if (isBtcLike) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.wallet_send_amount_in_sats,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              Text(
                '${SatsInputFormatter.formatValue(amountInSats)} sats',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        SendConversionPreview(
          selectedAsset: selectedAsset,
          assetAmount: btcAmount,
        ),
        const SizedBox(height: 12),
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
    final positive = context.colors.positiveColor;

    final validationState = ref.watch(sendValidationControllerProvider);
    final hasAmountInvalidatingError = validationState.errors.any((e) {
      final cat = e.category;
      return cat == SendValidationErrorCategory.amount ||
          cat == SendValidationErrorCategory.limits ||
          cat == SendValidationErrorCategory.balance;
    });
    if (hasAmountInvalidatingError) return const SizedBox.shrink();

    if (network == Blockchain.liquid || network == Blockchain.bitcoin) {
      return _Chip(
        icon: Icons.check_circle_outline_rounded,
        text: t.wallet_send_amount_valid,
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
