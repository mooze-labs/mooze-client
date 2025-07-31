import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/wallet/providers/visibility_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:shimmer/shimmer.dart';

const double balanceFontSize = 32.0;

class WalletBalanceDisplay extends ConsumerWidget {
  const WalletBalanceDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(visibilityProvider);
    final balance = ref.watch(balanceProvider(Asset.btc));

    return balance.when(
        data: (data) => data.fold(
                (err) => ErrorWalletBalanceDisplay(),
                (val) => SuccessfulWalletBalanceDisplay(balanceAmount: val, isVisible: isVisible)
        ),
        error: (err, stackTrace) => ErrorWalletBalanceDisplay(),
        loading: () => LoadingWalletBalanceDisplay()
    );
  }
}

class SuccessfulWalletBalanceDisplay extends StatelessWidget {
  final BigInt balanceAmount;
  final bool isVisible;

  const SuccessfulWalletBalanceDisplay({super.key, required this.balanceAmount, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    final displayText = isVisible ? "******" : balanceAmount.toString();
    return Text(displayText, style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: balanceFontSize,
        fontWeight: FontWeight.bold
    ));
  }
}

class ErrorWalletBalanceDisplay extends StatelessWidget {
  const ErrorWalletBalanceDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Text("N/A", style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: balanceFontSize,
        fontWeight: FontWeight.bold)
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
        height: balanceFontSize,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
