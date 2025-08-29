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

class AmountField extends ConsumerWidget {
  const AmountField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Asset selectedAsset = ref.read(selectedAssetProvider);
    final inputAmount = ref.read(amountStateProvider);

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
              child: Text(
                (inputAmount == 0.0)
                    ? "Digite a quantidade"
                    : inputAmount.toString(),
              ),
            ),
            MaxButton(),
          ],
        ),
      ),
    );
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quantia',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
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
                    hintText: '0.00',
                    hintStyle: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 18,
                    ),
                    filled: true,
                    fillColor: AppColors.pinBackground,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: "Cancelar",
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    text: "OK",
                    onPressed: () {
                      final selectedAsset = ref.read(selectedAssetProvider);
                      final eitherAmount = parseInputAmount(
                        _controller.text.trim(),
                        selectedAsset,
                      );

                      eitherAmount.fold(
                        (err) => ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(err))),
                        (data) =>
                            ref.read(amountStateProvider.notifier).state = data,
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
