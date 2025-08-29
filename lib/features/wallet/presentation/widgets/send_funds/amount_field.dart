import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_balance_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

import '../../providers/send_funds/amount_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/amount_display_mode_provider.dart';
import '../../providers/send_funds/bitcoin_price_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';

class AmountField extends ConsumerWidget {
  const AmountField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Asset selectedAsset = ref.watch(selectedAssetProvider);
    final inputAmount = ref.watch(amountStateProvider);
    final displayMode = ref.watch(amountDisplayModeProvider);
    final bitcoinPrice = ref.watch(bitcoinPriceProvider);
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
              child: bitcoinPrice.when(
                data:
                    (btcPrice) => Text(
                      (inputAmount == 0)
                          ? "Digite a quantidade"
                          : _formatDisplayAmount(
                            inputAmount,
                            selectedAsset,
                            displayMode,
                            btcPrice,
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
                            currencySymbol,
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
    String currencySymbol,
  ) {
    if (asset != Asset.btc) {
      return amountInSats.toString();
    }

    switch (displayMode) {
      case AmountDisplayMode.fiat:
        if (bitcoinPrice == null || bitcoinPrice == 0) {
          return "$currencySymbol --";
        }
        final btcAmount = amountInSats / 100000000;
        final fiatValue = btcAmount * bitcoinPrice;
        return "$currencySymbol ${fiatValue.toStringAsFixed(2)}";

      case AmountDisplayMode.bitcoin:
        final btcAmount = amountInSats / 100000000;
        return "${btcAmount.toStringAsFixed(8)} BTC";

      case AmountDisplayMode.satoshis:
        final satText = amountInSats == 1 ? 'sat' : 'sats';
        return "$amountInSats $satText";
    }
  }
}

class MaxButton extends ConsumerWidget {
  const MaxButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAssetBalance = ref.read(selectedAssetBalanceProvider);

    return selectedAssetBalance.when(
      data:
          (data) => data.fold(
            (err) => SizedBox.shrink(),
            (amount) => GestureDetector(
              onTap:
                  () =>
                      ref.read(amountStateProvider.notifier).state =
                          amount.toInt(),
              child: Text(
                "MAX",
                style: Theme.of(
                  context,
                ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.bold),
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
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with current amount if exists
    final currentAmount = ref.read(amountStateProvider);
    if (currentAmount > 0) {
      final asset = ref.read(selectedAssetProvider);
      final displayMode = ref.read(amountDisplayModeProvider);
      final bitcoinPriceAsync = ref.read(bitcoinPriceProvider);

      final bitcoinPrice =
          bitcoinPriceAsync.value; // Extract value from AsyncValue

      _controller.text = _getInitialDisplayValue(
        currentAmount,
        asset,
        displayMode,
        bitcoinPrice,
      );
    }
  }

  String _getInitialDisplayValue(
    int amountInSats,
    Asset asset,
    AmountDisplayMode displayMode,
    double? bitcoinPrice,
  ) {
    if (asset != Asset.btc) {
      return (amountInSats / 100000000).toString();
    }

    switch (displayMode) {
      case AmountDisplayMode.fiat:
        if (bitcoinPrice == null || bitcoinPrice == 0) return "";
        final btcAmount = amountInSats / 100000000;
        final fiatValue = btcAmount * bitcoinPrice;
        return fiatValue.toStringAsFixed(2);

      case AmountDisplayMode.bitcoin:
        final btcAmount = amountInSats / 100000000;
        return btcAmount.toStringAsFixed(8);

      case AmountDisplayMode.satoshis:
        return amountInSats.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAsset = ref.watch(selectedAssetProvider);
    final displayMode = ref.watch(amountDisplayModeProvider);
    final validation = ref.watch(sendValidationControllerProvider);

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
            if (selectedAsset == Asset.btc) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      final newMode = displayMode.next;
                      ref.read(amountDisplayModeProvider.notifier).state =
                          newMode;
                      _updateControllerForNewMode(newMode);
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
                            displayMode.label,
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
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantia em ${selectedAsset == Asset.btc ? displayMode.label : selectedAsset.ticker}',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
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
            if (selectedAsset == Asset.btc) ...[
              const SizedBox(height: 8),
              Text(
                'Valor mínimo: 25.000 sats',
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
    if (asset != Asset.btc) return '0.00';

    switch (displayMode) {
      case AmountDisplayMode.fiat:
        return '0,00';
      case AmountDisplayMode.bitcoin:
        return '0.00000000';
      case AmountDisplayMode.satoshis:
        return '25000';
    }
  }

  void _updateControllerForNewMode(AmountDisplayMode newMode) {
    final currentText = _controller.text.trim();
    if (currentText.isEmpty) return;

    final currentAmount = ref.read(amountStateProvider);
    if (currentAmount <= 0) return;

    final selectedAsset = ref.read(selectedAssetProvider);
    final bitcoinPriceAsync = ref.read(bitcoinPriceProvider);

    final bitcoinPrice =
        bitcoinPriceAsync.value; // Extract value from AsyncValue

    _controller.text = _getInitialDisplayValue(
      currentAmount,
      selectedAsset,
      newMode,
      bitcoinPrice,
    );
  }

  void _saveAmount() {
    final selectedAsset = ref.read(selectedAssetProvider);
    final displayMode = ref.read(amountDisplayModeProvider);
    final bitcoinPriceAsync = ref.read(bitcoinPriceProvider);

    final bitcoinPrice =
        bitcoinPriceAsync.value; // Extract value from AsyncValue

    final eitherAmount = _parseInputAmountWithMode(
      _controller.text.trim(),
      selectedAsset,
      displayMode,
      bitcoinPrice,
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
  ) {
    if (input.isEmpty) {
      return const Left("Valor não pode estar vazio");
    }

    if (asset != Asset.btc) {
      return parseStablecoinAmount(input);
    }

    switch (displayMode) {
      case AmountDisplayMode.fiat:
        return _parseFiatAmount(input, bitcoinPrice);
      case AmountDisplayMode.bitcoin:
        return _parseBtcAmount(input);
      case AmountDisplayMode.satoshis:
        return _parseSatsAmount(input);
    }
  }

  Either<String, int> _parseFiatAmount(String input, double? bitcoinPrice) {
    if (bitcoinPrice == null || bitcoinPrice == 0) {
      return const Left("Preço do Bitcoin não disponível");
    }

    try {
      final fiatValue = double.parse(input.replaceAll(',', '.'));
      if (fiatValue <= 0) {
        return const Left("Valor deve ser maior que zero");
      }

      final btcAmount = fiatValue / bitcoinPrice;
      final satoshis = (btcAmount * 100000000).round();

      if (satoshis < 25000) {
        return const Left("Valor mínimo é 25.000 sats");
      }

      return Right(satoshis);
    } catch (e) {
      return const Left("Formato inválido");
    }
  }

  Either<String, int> _parseBtcAmount(String input) {
    try {
      final btcValue = double.parse(input.replaceAll(',', '.'));
      if (btcValue <= 0) {
        return const Left("Valor deve ser maior que zero");
      }

      final satoshis = (btcValue * 100000000).round();

      if (satoshis < 25000) {
        return const Left("Valor mínimo é 25.000 sats");
      }

      return Right(satoshis);
    } catch (e) {
      return const Left("Formato inválido");
    }
  }

  Either<String, int> _parseSatsAmount(String input) {
    try {
      final satoshis = int.parse(input);
      if (satoshis <= 0) {
        return const Left("Valor deve ser maior que zero");
      }

      if (satoshis < 25000) {
        return const Left("Valor mínimo é 25.000 sats");
      }

      return Right(satoshis);
    } catch (e) {
      return const Left("Formato inválido");
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

  // Remove whitespace
  final trimmed = input.trim();

  // Check if it contains decimal separators
  if (trimmed.contains('.') || trimmed.contains(',')) {
    return const Left("Bitcoin deve ser um valor em satoshis");
  }

  // Try to parse as integer
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

  // Remove whitespace
  final trimmed = input.trim();

  // Normalize decimal separator - handle both comma and dot
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
