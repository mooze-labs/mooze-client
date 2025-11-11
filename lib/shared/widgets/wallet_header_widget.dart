import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_total_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_display_mode_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class WalletHeaderWidget extends ConsumerWidget {
  const WalletHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(isVisibleProvider);
    final displayMode = ref.watch(walletDisplayModeProvider);

    final totalFiatValue = ref.watch(totalWalletValueProvider);
    final totalBitcoinValue = ref.watch(totalWalletBitcoinProvider);
    final totalSatoshisValue = ref.watch(totalWalletSatoshisProvider);
    final totalVariation = ref.watch(totalWalletVariationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Minha Carteira',
              style: TextStyle(color: Color(0xFF9194A6), fontSize: 16),
            ),
            IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.white,
              ),
              onPressed: () {
                ref.read(isVisibleProvider.notifier).toggle();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTotalValue(
              ref,
              displayMode,
              totalFiatValue,
              totalBitcoinValue,
              totalSatoshisValue,
              isVisible,
            ),
            const SizedBox(width: 12),
            _buildVariationPercentage(totalVariation),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalValue(
    WidgetRef ref,
    WalletDisplayMode displayMode,
    AsyncValue<Either<String, double>> totalFiatValue,
    AsyncValue<Either<String, double>> totalBitcoinValue,
    AsyncValue<Either<String, BigInt>> totalSatoshisValue,
    bool isVisible,
  ) {
    final currencyIcon = ref.watch(currencyControllerProvider.notifier).icon;

    late AsyncValue value;
    late String Function(dynamic) formatter;

    switch (displayMode) {
      case WalletDisplayMode.fiat:
        value = totalFiatValue;
        formatter = (val) => '$currencyIcon ${val.toStringAsFixed(2)}';
        break;
      case WalletDisplayMode.bitcoin:
        value = totalBitcoinValue;
        formatter = (val) => '${val.toStringAsFixed(8)} BTC';
        break;
      case WalletDisplayMode.satoshis:
        value = totalSatoshisValue;
        formatter = (val) {
          final formattedSats = SatsInputFormatter.formatValue(val.toInt());
          return '$formattedSats ${val == BigInt.one ? 'sat' : 'sats'}';
        };
        break;
    }

    return GestureDetector(
      onTap: () {
        ref.read(walletDisplayModeProvider.notifier).state = displayMode.next;
      },
      child: value.when(
        data:
            (either) => either.fold(
              (error) => const Text(
                'N/A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              (total) => Text(
                isVisible ? '•••••••' : formatter(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        loading: () => _buildLoadingText(),
        error:
            (_, _) => const Text(
              'N/A',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  Widget _buildVariationPercentage(
    AsyncValue<Either<String, double>> totalVariation,
  ) {
    return totalVariation.when(
      data:
          (data) => data.fold((error) => const SizedBox.shrink(), (variation) {
            if (variation == 0.0) return const SizedBox.shrink();

            final isPositive = variation > 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isPositive
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${variation.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
      error: (_, _) => const SizedBox.shrink(),
      loading: () => _buildLoadingPercentage(),
    );
  }

  Widget _buildLoadingText() {
    return Shimmer.fromColors(
      baseColor: AppColors.baseColor,
      highlightColor: AppColors.highlightColor,
      child: Container(
        width: 150,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.baseColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildLoadingPercentage() {
    return Shimmer.fromColors(
      baseColor: AppColors.baseColor,
      highlightColor: AppColors.highlightColor,
      child: Container(
        width: 60,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.baseColor,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
