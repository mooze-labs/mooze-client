import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import '../../providers/balance_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';
import '../../providers/send_funds/drain_provider.dart';
import '../../providers/send_funds/transaction_loading_provider.dart';
import '../../providers/send_funds/partially_signed_transaction_provider.dart';
import '../../providers/send_funds/prepared_psbt_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/selected_network_provider.dart';

class ReviewButton extends ConsumerWidget {
  const ReviewButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validation = ref.watch(sendValidationControllerProvider);
    final isDrainTransaction = ref.watch(isDrainTransactionProvider);
    final preparationState = ref.watch(
      transactionPreparationControllerProvider,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          if (preparationState.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      preparationState.errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
          ],
          PrimaryButton(
            text:
                preparationState.isLoading
                    ? "Preparando..."
                    : (isDrainTransaction
                        ? "Revisar Envio Total"
                        : "Revisar Transação"),
            onPressed:
                (validation.canProceed && !preparationState.isLoading)
                    ? () => _prepareTransaction(context, ref)
                    : null,
            isEnabled: validation.canProceed && !preparationState.isLoading,
            isLoading: preparationState.isLoading,
          ),
        ],
      ),
    );
  }

  Future<void> _prepareTransaction(BuildContext context, WidgetRef ref) async {
    final asset = ref.read(selectedAssetProvider);
    final blockchain = ref.read(selectedNetworkProvider);

    if (asset == Asset.btc && blockchain == Blockchain.bitcoin) {
      final preparationController = ref.read(
        transactionPreparationControllerProvider.notifier,
      );

      preparationController.startLoading();

      await ref
          .read(sendValidationControllerProvider.notifier)
          .validateTransaction();

      final finalValidation = ref.read(sendValidationControllerProvider);

      if (!finalValidation.canProceed || finalValidation.errors.isNotEmpty) {
        preparationController.reset();
        return;
      }

      try {
        ref.invalidate(psbtProvider);

        final psbtResult = await ref.read(psbtProvider.future);

        psbtResult.fold(
          (error) async {
            final errorMessage = await _parseInsufficientFundsError(error, ref);
            preparationController.setError(errorMessage);
          },
          (psbt) {
            ref.read(preparedPsbtProvider.notifier).state = psbt;

            preparationController.setSuccess();
            if (!context.mounted) return;
            context.push('/send-funds/review-onchain');
          },
        );
      } catch (e) {
        final errorMessage = await _parseInsufficientFundsError(
          e.toString(),
          ref,
        );
        preparationController.setError(errorMessage);
      }
      return;
    }

    final preparationController = ref.read(
      transactionPreparationControllerProvider.notifier,
    );

    preparationController.startLoading();

    await ref
        .read(sendValidationControllerProvider.notifier)
        .validateTransaction();

    final finalValidation = ref.read(sendValidationControllerProvider);

    if (!finalValidation.canProceed || finalValidation.errors.isNotEmpty) {
      preparationController.reset();

      return;
    }

    try {
      ref.invalidate(psbtProvider);

      final psbtResult = await ref.read(psbtProvider.future);

      psbtResult.fold(
        (error) async {
          final errorMessage = await _parseInsufficientFundsError(error, ref);
          preparationController.setError(errorMessage);
        },
        (psbt) {
          preparationController.setSuccess();
          context.push('/send-funds/review-simple');
        },
      );
    } catch (e) {
      final errorMessage = await _parseInsufficientFundsError(
        e.toString(),
        ref,
      );
      preparationController.setError(errorMessage);
    }
  }

  Future<String> _parseInsufficientFundsError(
    String error,
    WidgetRef ref,
  ) async {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('not enough funds') ||
        errorLower.contains('insufficient') ||
        errorLower.contains('insuficient') ||
        errorLower.contains('insufficientfunds') ||
        errorLower.contains('cannot pay')) {
      final asset = ref.read(selectedAssetProvider);
      final blockchain = ref.read(selectedNetworkProvider);

      // Check if user has L-BTC balance for fees when sending DePIX or USDT
      if ((asset == Asset.depix || asset == Asset.usdt) &&
          blockchain == Blockchain.liquid) {
        try {
          final lbtcBalanceResult = await ref.read(
            balanceProvider(Asset.lbtc).future,
          );

          final hasLbtcBalance = lbtcBalanceResult.fold(
            (error) => false,
            (balance) => balance > BigInt.zero,
          );

          if (!hasLbtcBalance) {
            return 'Saldo de BTC L2 insuficiente para taxas.\n\n'
                'Para enviar ${asset == Asset.depix ? 'DePIX' : 'USDT'}, você precisa ter BTC L2 '
                '(Bitcoin Liquid) disponível para pagar as taxas da transação. '
                'Adicione BTC L2 à sua carteira e tente novamente.';
          }
        } catch (e) {} // Ignore errors fetching balance
      }

      return 'Fundos insuficientes.\n\n'
          'O valor que você está tentando enviar mais as taxas da rede '
          'excedem o saldo disponível. Tente reduzir o valor ou use a opção '
          '"Enviar Tudo" para enviar o máximo possível com as taxas deduzidas automaticamente.';
    }

    return 'Erro ao preparar transação: $error';
  }
}
