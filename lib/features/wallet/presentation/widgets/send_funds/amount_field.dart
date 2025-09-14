import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_balance_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

import '../../providers/send_funds/amount_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/amount_display_mode_provider.dart';
import '../../providers/send_funds/bitcoin_price_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';
import '../../providers/send_funds/selected_network_provider.dart';
import '../../providers/send_funds/amount_controller_provider.dart';
import '../../providers/send_funds/address_provider.dart';

class AmountField extends ConsumerWidget {
  const AmountField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Asset selectedAsset = ref.watch(selectedAssetProvider);
    final inputAmount = ref.watch(amountStateProvider);
    final displayMode = ref.watch(amountDisplayModeProvider);
    final bitcoinPrice = ref.watch(bitcoinPriceProvider);
    final selectedAssetPrice = ref.watch(selectedAssetPriceProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return GestureDetector(
      onTap: () => showAmountModal(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pinBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset(selectedAsset.iconPath, width: 21, height: 21),
            const SizedBox(width: 12),
            Expanded(
              child: selectedAssetPrice.when(
                data:
                    (assetPrice) => bitcoinPrice.when(
                      data:
                          (btcPrice) => Text(
                            (inputAmount == 0)
                                ? "Digite a quantidade"
                                : _formatDisplayAmount(
                                  inputAmount,
                                  selectedAsset,
                                  displayMode,
                                  btcPrice,
                                  assetPrice,
                                  currencySymbol,
                                ),
                          ),
                      loading: () => const Text("Carregando..."),
                      error:
                          (error, _) => Text(
                            (inputAmount == 0)
                                ? "Digite a quantidade"
                                : _formatDisplayAmount(
                                  inputAmount,
                                  selectedAsset,
                                  displayMode,
                                  null,
                                  assetPrice,
                                  currencySymbol,
                                ),
                          ),
                    ),
                loading: () => const Text("Carregando..."),
                error:
                    (error, _) => bitcoinPrice.when(
                      data:
                          (btcPrice) => Text(
                            (inputAmount == 0)
                                ? "Digite a quantidade"
                                : _formatDisplayAmount(
                                  inputAmount,
                                  selectedAsset,
                                  displayMode,
                                  btcPrice,
                                  null,
                                  currencySymbol,
                                ),
                          ),
                      loading: () => const Text("Carregando..."),
                      error:
                          (error, _) => Text(
                            (inputAmount == 0)
                                ? "Digite a quantidade"
                                : _formatDisplayAmount(
                                  inputAmount,
                                  selectedAsset,
                                  displayMode,
                                  null,
                                  null,
                                  currencySymbol,
                                ),
                          ),
                    ),
              ),
            ),
            MaxButton(),
          ],
        ),
      ),
    );
  }

  String _formatDisplayAmount(
    int amountInSats,
    Asset asset,
    AmountDisplayMode displayMode,
    double? bitcoinPrice,
    double? selectedAssetPrice,
    String currencySymbol,
  ) {
    final BigInt amount = BigInt.from(amountInSats);
    final double? priceToUse =
        asset == Asset.btc ? bitcoinPrice : selectedAssetPrice;

    return displayMode.formatAmount(asset, amount, priceToUse, currencySymbol);
  }
}

class MaxButton extends ConsumerWidget {
  const MaxButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAssetBalance = ref.watch(selectedAssetBalanceRawProvider);
    final selectedAsset = ref.watch(selectedAssetProvider);
    final destination = ref.watch(addressStateProvider);

    return selectedAssetBalance.when(
      data:
          (data) => data.fold(
            (err) => SizedBox.shrink(),
            (amount) => GestureDetector(
              onTap: () {
                ref.read(amountStateProvider.notifier).state = amount.toInt();

                if (selectedAsset == Asset.btc) {
                  ref.read(amountDisplayModeProvider.notifier).state =
                      AmountDisplayMode.fiat;
                } else {
                  ref.read(amountDisplayModeProvider.notifier).state =
                      AmountDisplayMode.fiat;
                }
              },
              child: Text(
                "MAX",
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
      error: (err, _) => SizedBox.shrink(),
      loading: () => SizedBox.shrink(),
    );
  }
}

class AmountModal extends ConsumerStatefulWidget {
  const AmountModal({super.key});

  @override
  ConsumerState<AmountModal> createState() => _AddressModalState();
}

class _AddressModalState extends ConsumerState<AmountModal> {
  @override
  void initState() {
    super.initState();
    final currentAmount = ref.read(amountStateProvider);
    if (currentAmount > 0) {
      final asset = ref.read(selectedAssetProvider);
      final displayMode = ref.read(amountDisplayModeProvider);
      final bitcoinPriceAsync = ref.read(bitcoinPriceProvider);
      final selectedAssetPriceAsync = ref.read(selectedAssetPriceProvider);

      final bitcoinPrice = bitcoinPriceAsync.value;
      final selectedAssetPrice = selectedAssetPriceAsync.value;

      final controller = ref.read(amountControllerProvider);
      controller.text = _getInitialDisplayValue(
        currentAmount,
        asset,
        displayMode,
        bitcoinPrice,
        selectedAssetPrice,
      );
    }
  }

  String _getInitialDisplayValue(
    int amountInSats,
    Asset asset,
    AmountDisplayMode displayMode,
    double? bitcoinPrice,
    double? selectedAssetPrice,
  ) {
    final BigInt amount = BigInt.from(amountInSats);
    final double? priceToUse =
        asset == Asset.btc ? bitcoinPrice : selectedAssetPrice;
    final currencySymbol = ref.read(currencySymbolProvider);

    if (priceToUse == null || priceToUse == 0) return "";

    try {
      final formatted = displayMode.formatAmount(
        asset,
        amount,
        priceToUse,
        currencySymbol,
      );
      return formatted.replaceAll(RegExp(r'[^\d.,]'), '').trim();
    } catch (e) {
      return "";
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAsset = ref.watch(selectedAssetProvider);
    final selectedNetwork = ref.watch(selectedNetworkProvider);
    final displayMode = ref.watch(amountDisplayModeProvider);
    final validation = ref.watch(sendValidationControllerProvider);
    final controller = ref.watch(amountControllerProvider);

    final hasMinimumValue =
        selectedAsset == Asset.btc && selectedNetwork == Blockchain.bitcoin;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Definir Quantia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (selectedAsset == Asset.btc) {
                      final newMode = displayMode.next;
                      ref.read(amountDisplayModeProvider.notifier).state =
                          newMode;
                      _updateControllerForNewMode(newMode);
                    } else {
                      final newMode =
                          displayMode == AmountDisplayMode.fiat
                              ? AmountDisplayMode.bitcoin
                              : AmountDisplayMode.fiat;
                      ref.read(amountDisplayModeProvider.notifier).state =
                          newMode;
                      _updateControllerForNewMode(newMode);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getDisplayModeLabel(selectedAsset, displayMode),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantia em ${_getDisplayModeLabel(selectedAsset, displayMode)}',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: _getHintText(selectedAsset, displayMode),
                    hintStyle: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 18,
                    ),
                    filled: true,
                    fillColor: AppColors.pinBackground,
                    contentPadding: const EdgeInsets.all(16),
                    errorText:
                        validation.errors.isNotEmpty
                            ? validation.errors.first
                            : null,
                  ),
                ),
              ],
            ),
            if (hasMinimumValue) ...[
              const SizedBox(height: 8),
              Text(
                'Valor mínimo: 25.000 sats (rede Bitcoin)',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: "Cancelar",
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    text: "OK",
                    onPressed: () => _saveAmount(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getHintText(Asset asset, AmountDisplayMode displayMode) {
    if (asset == Asset.btc) {
      switch (displayMode) {
        case AmountDisplayMode.fiat:
          return '0,00';
        case AmountDisplayMode.bitcoin:
          return '0.00000000';
        case AmountDisplayMode.satoshis:
          return '25000';
      }
    } else {
      switch (displayMode) {
        case AmountDisplayMode.fiat:
          return '0,00';
        case AmountDisplayMode.bitcoin:
        case AmountDisplayMode.satoshis:
          return '0.00';
      }
    }
  }

  String _getDisplayModeLabel(Asset asset, AmountDisplayMode displayMode) {
    final currencySymbol = ref.read(currencySymbolProvider);

    if (asset == Asset.btc) {
      return displayMode.label(currencySymbol);
    } else {
      return displayMode == AmountDisplayMode.fiat
          ? displayMode.label(currencySymbol)
          : asset.ticker;
    }
  }

  void _updateControllerForNewMode(AmountDisplayMode newMode) {
    final controller = ref.read(amountControllerProvider);
    final currentText = controller.text.trim();
    if (currentText.isEmpty) return;

    final currentAmount = ref.read(amountStateProvider);
    if (currentAmount <= 0) return;

    final selectedAsset = ref.read(selectedAssetProvider);
    final bitcoinPriceAsync = ref.read(bitcoinPriceProvider);
    final selectedAssetPriceAsync = ref.read(selectedAssetPriceProvider);

    final bitcoinPrice = bitcoinPriceAsync.value;
    final selectedAssetPrice = selectedAssetPriceAsync.value;

    controller.text = _getInitialDisplayValue(
      currentAmount,
      selectedAsset,
      newMode,
      bitcoinPrice,
      selectedAssetPrice,
    );
  }

  void _saveAmount() {
    final controller = ref.read(amountControllerProvider);
    final selectedAsset = ref.read(selectedAssetProvider);
    final selectedNetwork = ref.read(selectedNetworkProvider);
    final displayMode = ref.read(amountDisplayModeProvider);
    final bitcoinPriceAsync = ref.read(bitcoinPriceProvider);
    final selectedAssetPriceAsync = ref.read(selectedAssetPriceProvider);

    final bitcoinPrice = bitcoinPriceAsync.value;
    final selectedAssetPrice = selectedAssetPriceAsync.value;

    final hasMinimumValue =
        selectedAsset == Asset.btc && selectedNetwork == Blockchain.bitcoin;

    final eitherAmount = _parseInputAmountWithMode(
      controller.text.trim(),
      selectedAsset,
      displayMode,
      bitcoinPrice,
      selectedAssetPrice,
      hasMinimumValue,
    );

    eitherAmount.fold(
      (err) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err))),
      (data) {
        ref.read(amountStateProvider.notifier).state = data;
        ref
            .read(sendValidationControllerProvider.notifier)
            .validateTransaction();
        Navigator.pop(context);
      },
    );
  }

  Either<String, int> _parseInputAmountWithMode(
    String input,
    Asset asset,
    AmountDisplayMode displayMode,
    double? bitcoinPrice,
    double? selectedAssetPrice,
    bool hasMinimumValue,
  ) {
    if (input.isEmpty) {
      return const Left("Valor não pode estar vazio");
    }

    try {
      final double? priceToUse =
          asset == Asset.btc ? bitcoinPrice : selectedAssetPrice;
      final BigInt satoshis = displayMode.parseInput(asset, input, priceToUse);

      if (hasMinimumValue && satoshis.toInt() < 25000) {
        return const Left("Valor mínimo é 25.000 sats para rede Bitcoin");
      }

      return Right(satoshis.toInt());
    } catch (e) {
      return Left(e.toString());
    }
  }
}

void showAmountModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AmountModal(),
  );
}

Either<String, int> parseInputAmount(String input, Asset asset) {
  if (asset == Asset.btc) return parseBitcoinAmount(input);

  return parseStablecoinAmount(input);
}

Either<String, int> parseBitcoinAmount(String input) {
  if (input.isEmpty) {
    return const Left("Valor não pode estar vazio");
  }

  final trimmed = input.trim();

  if (trimmed.contains('.') || trimmed.contains(',')) {
    return const Left("Bitcoin deve ser um valor em satoshis");
  }

  try {
    final parsed = int.parse(trimmed);
    if (parsed <= 0) {
      return const Left("Valor deve ser maior que zero");
    }
    return Right(parsed);
  } catch (e) {
    return const Left("Formato inválido");
  }
}

Either<String, int> parseStablecoinAmount(String input) {
  if (input.isEmpty) {
    return const Left("Valor não pode estar vazio");
  }

  final trimmed = input.trim();

  String normalized = trimmed;

  // Count occurrences of both separators
  final dotCount = trimmed.split('.').length - 1;
  final commaCount = trimmed.split(',').length - 1;

  // Handle different locale formats
  if (dotCount > 1 || commaCount > 1) {
    return const Left("Formato inválido");
  }

  if (dotCount == 1 && commaCount == 1) {
    // Both separators present - determine which is decimal
    final lastDotIndex = trimmed.lastIndexOf('.');
    final lastCommaIndex = trimmed.lastIndexOf(',');

    if (lastDotIndex > lastCommaIndex) {
      // Dot is decimal separator, comma is thousands separator
      normalized = trimmed.replaceAll(',', '');
    } else {
      // Comma is decimal separator, dot is thousands separator
      normalized = trimmed.replaceAll('.', '').replaceAll(',', '.');
    }
  } else if (commaCount == 1) {
    // Only comma present - treat as decimal separator
    normalized = trimmed.replaceAll(',', '.');
  }

  // Try to parse as double
  try {
    final parsed = double.parse(normalized);
    if (parsed <= 0) {
      return const Left("Valor deve ser maior que zero");
    }

    // Convert to satoshis (multiply by 10^8)
    final satoshis = (parsed * pow(10, 8)).round();
    return Right(satoshis);
  } catch (e) {
    return const Left("Formato inválido");
  }
}
