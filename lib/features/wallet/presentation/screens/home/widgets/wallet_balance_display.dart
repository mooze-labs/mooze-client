import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/home/providers/visibility_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:shimmer/shimmer.dart';

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

class SuccessfulWalletBalanceDisplay extends StatelessWidget {
  final BigInt balanceAmount;
  final bool isVisible;

  const SuccessfulWalletBalanceDisplay({
    super.key,
    required this.balanceAmount,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = isVisible ? "********" : balanceAmount.toString();
    return Text(
      'R\$${displayText}',
      style: Theme.of(
        context,
      ).textTheme.displayLarge!.copyWith(fontWeight: FontWeight.bold),
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
        width: 120, // Approximate width for a typical balance display
        height: 32,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
