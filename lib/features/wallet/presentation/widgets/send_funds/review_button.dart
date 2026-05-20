import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';

import '../../providers/balance_provider.dart';
import '../../providers/send_funds/drain_provider.dart';
import '../../providers/send_funds/partially_signed_transaction_provider.dart';
import '../../providers/send_funds/prepared_psbt_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/selected_network_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';
import '../../providers/send_funds/transaction_loading_provider.dart';
import 'lbtc_insufficient_funds_dialog.dart';

class ReviewButton extends ConsumerWidget {
  const ReviewButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final validation = ref.watch(sendValidationControllerProvider);
    final isDrainTransaction = ref.watch(isDrainTransactionProvider);
    final preparationState = ref.watch(
      transactionPreparationControllerProvider,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: preparationState.errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PreparationErrorCard(
                    message: preparationState.errorMessage!,
                    onDismiss: () => ref
                        .read(transactionPreparationControllerProvider.notifier)
                        .reset(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        PrimaryButton(
          text: preparationState.isLoading
              ? t.wallet_send_review_preparing
              : (isDrainTransaction
                  ? t.wallet_send_review_drain
                  : t.wallet_send_review_transaction),
          onPressed: (validation.canProceed && !preparationState.isLoading)
              ? () => _prepareTransaction(context, ref)
              : null,
          isEnabled: validation.canProceed && !preparationState.isLoading,
          isLoading: preparationState.isLoading,
        ),
      ],
    );
  }

  Future<void> _prepareTransaction(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
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
            final errorMessage = await _parseError(error, ref, t);
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
        final errorMessage = await _parseError(e.toString(), ref, t);
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
          final isLbtcError = await _handleInsufficientLbtcError(
            error,
            ref,
            context,
            preparationController,
          );
          if (!isLbtcError) {
            final errorMessage = await _parseError(error, ref, t);
            preparationController.setError(errorMessage);
          }
        },
        (psbt) {
          preparationController.setSuccess();
          if (!context.mounted) return;
          context.push('/send-funds/review-simple');
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      final isLbtcError = await _handleInsufficientLbtcError(
        e.toString(),
        ref,
        context,
        preparationController,
      );
      if (!isLbtcError) {
        final errorMessage = await _parseError(e.toString(), ref, t);
        preparationController.setError(errorMessage);
      }
    }
  }

  Future<bool> _handleInsufficientLbtcError(
    String error,
    WidgetRef ref,
    BuildContext context,
    dynamic preparationController,
  ) async {
    if (!_isInsufficientFundsError(error)) return false;

    final asset = ref.read(selectedAssetProvider);
    final blockchain = ref.read(selectedNetworkProvider);

    if ((asset == Asset.depix || asset == Asset.usdt) &&
        blockchain == Blockchain.liquid) {
      final router = GoRouter.of(context);

      try {
        final lbtcBalanceResult = await ref.read(
          balanceProvider(Asset.lbtc).future,
        );

        final hasLbtcBalance = lbtcBalanceResult.fold(
          (error) => false,
          (balance) => balance > BigInt.zero,
        );

        if (!hasLbtcBalance) {
          preparationController.reset();
          if (!context.mounted) return true;

          final goToSwap = await LbtcInsufficientFundsDialog.show(
            context,
            asset: asset,
          );

          if (goToSwap == true) {
            router.go('/swap');
          }
          return true;
        }
      } catch (_) {
        // If balance check fails, fall through to generic error
      }
    }

    return false;
  }

  bool _isInsufficientFundsError(String error) {
    final errorLower = error.toLowerCase();
    return errorLower.contains('not enough funds') ||
        errorLower.contains('insufficient') ||
        errorLower.contains('insuficient') ||
        errorLower.contains('insufficientfunds') ||
        errorLower.contains('cannot pay');
  }

  Future<String> _parseError(
    String error,
    WidgetRef ref,
    AppLocalizations t,
  ) async {
    if (_isInsufficientFundsError(error)) {
      final asset = ref.read(selectedAssetProvider);
      final blockchain = ref.read(selectedNetworkProvider);

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
            final assetName = asset == Asset.depix ? 'DePIX' : 'USDT';
            return t.wallet_send_review_lbtc_insufficient_error(assetName);
          }
        } catch (_) {}
      }

      return t.wallet_send_review_insufficient_error;
    }

    return t.wallet_send_review_prepare_error;
  }
}

class _PreparationErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _PreparationErrorCard({
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: cs.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.error.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _DismissButton(onTap: onDismiss),
        ],
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DismissButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            Icons.close_rounded,
            size: 16,
            color: cs.error.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
