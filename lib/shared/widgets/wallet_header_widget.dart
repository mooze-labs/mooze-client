import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fpdart/fpdart.dart' hide State;
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
            const SizedBox(width: 8),
            _buildVariationPercentage(totalVariation),
            Spacer(),
            const SizedBox(height: 12),
            _buildPendingTransactionsBadge(),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingTransactionsBadge() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 1),
      ),
      child: _AnimatedPixIcon(),
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

class _AnimatedPixIcon extends StatefulWidget {
  const _AnimatedPixIcon();

  @override
  State<_AnimatedPixIcon> createState() => _AnimatedPixIconState();
}

class _AnimatedPixIconState extends State<_AnimatedPixIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: SvgPicture.asset(
            'assets/icons/menu/navigation/pix.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(Colors.orange, BlendMode.srcIn),
          ),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search,
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
