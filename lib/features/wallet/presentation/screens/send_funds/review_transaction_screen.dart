import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:mooze_mobile/shared/widgets/info_row.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/section_label.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/transaction_card.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/partially_signed_transaction_provider.dart';

class ReviewTransactionScreen extends ConsumerWidget {
  const ReviewTransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final psbt = ref.watch(psbtProvider);

    return psbt.when(
      data:
          (data) => data.fold(
            (err) => ErrorPsbtScreen(errorDescription: err),
            (psbt) => SuccessfulPsbtScreen(psbt: psbt),
          ),
      error: (err, _) => ErrorPsbtScreen(errorDescription: err.toString()),
      loading: () => LoadingPsbtScreen(),
    );
  }
}

class SuccessfulPsbtScreen extends StatelessWidget {
  final PartiallySignedTransaction psbt;

  const SuccessfulPsbtScreen({super.key, required this.psbt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Revisar transação")),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(label: "Endereço"),
            TransactionCard(content: psbt.destination),
            SizedBox(height: 16),
            SectionLabel(label: "Quantidade"),
            TransactionCard(
              content:
                  "${(psbt.satoshi / BigInt.from(pow(10, 8)))} ${psbt.asset.ticker}",
            ),
            SizedBox(height: 16),
            SectionLabel(label: "Dados adicionais"),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: cardPadding + 4,
                vertical: cardPadding,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  InfoRow(label: "Rede", value: psbt.blockchain.name),
                  InfoRow(
                    label: "Taxas de rede",
                    value: psbt.networkFees.toString(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingPsbtScreen extends StatelessWidget {
  const LoadingPsbtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: LoadingAnimationWidget.waveDots(
          color: Theme.of(context).colorScheme.primary,
          size: 200,
        ),
      ),
    );
  }
}

class ErrorPsbtScreen extends StatelessWidget {
  final String errorDescription;

  const ErrorPsbtScreen({super.key, required this.errorDescription});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Falha ao gerar endereço: $errorDescription")),
    );
  }
}
