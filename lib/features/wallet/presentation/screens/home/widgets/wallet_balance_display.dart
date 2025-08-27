import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/home/providers/visibility_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../../shared/prices/providers/currency_controller_provider.dart';

class WalletBalanceDisplay extends ConsumerWidget {
  const WalletBalanceDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(isVisibleProvider);
    final balance = ref.watch(balanceProvider(Asset.btc));

    return balance.when(
      data:
          (data) => data.fold(
            (err) {
              if (kDebugMode)
                debugPrint(
                  "[BREEZ BALANCE] ${err.description} ${err.customDescription}",
                );
              return ErrorWalletBalanceDisplay();
            },
            (val) => SuccessfulWalletBalanceDisplay(
              balanceAmount: val,
              isVisible: isVisible,
            ),
          ),
      error: (err, stackTrace) {
        if (kDebugMode) debugPrint("[BREEZ BALANCE] $err");
        return ErrorWalletBalanceDisplay();
      },
      loading: () => LoadingWalletBalanceDisplay(),
    );
  }
}

class SuccessfulWalletBalanceDisplay extends ConsumerWidget {
  final BigInt balanceAmount;
  final bool isVisible;

  const SuccessfulWalletBalanceDisplay({
    super.key,
    required this.balanceAmount,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = ref.watch(currencyControllerProvider.notifier).icon;
    final displayText = isVisible ? "********" : balanceAmount.toString();
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          icon,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          displayText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class ErrorWalletBalanceDisplay extends StatelessWidget {
  const ErrorWalletBalanceDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      "N/A",
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class LoadingWalletBalanceDisplay extends StatelessWidget {
  const LoadingWalletBalanceDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: 120,
        height: 32,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
