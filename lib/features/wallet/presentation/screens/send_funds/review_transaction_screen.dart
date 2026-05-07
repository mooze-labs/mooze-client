import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
// Phase 2.3.3: hide V2's `balanceProvider` to avoid colliding with the
// legacy `balanceProvider(Asset asset)` family this screen uses
// throughout. Phase 2.7 cleanup migrates the screen to V2's per-asset
// provider and removes the hide directive.
import 'package:mooze_mobile/app/di/v2_providers.dart' hide balanceProvider;
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/send_funds/network_detection_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';
import '../../providers/send_funds/partially_signed_transaction_provider.dart';
import '../../providers/send_funds/bitcoin_price_provider.dart';
import '../../providers/send_funds/drain_provider.dart';
import '../../providers/balance_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/send_funds/network_indicator_widget.dart';
import 'transaction_sent_screen.dart';

class ReviewTransactionScreen extends ConsumerStatefulWidget {
  const ReviewTransactionScreen({super.key});

  @override
  ConsumerState<ReviewTransactionScreen> createState() =>
      _ReviewTransactionScreenState();
}

class _ReviewTransactionScreenState
    extends ConsumerState<ReviewTransactionScreen> {
  bool _isConfirming = false;
  final _log = AppLoggerService();
  static const _tag = 'ReviewTransaction';

  @override
  Widget build(BuildContext context) {
    final psbtAsyncValue = ref.watch(psbtProvider);
    final bitcoinPrice = ref.watch(bitcoinPriceProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final validationState = ref.watch(sendValidationControllerProvider);
    final isDrainTransaction = ref.watch(isDrainTransactionProvider);

    return psbtAsyncValue.when(
      data:
          (psbtEither) => psbtEither.fold(
            (error) {
              _log.error(_tag, 'PSBT preparation returned an error: $error');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.pop();
              });
              return _buildErrorScreen(context, error);
            },
            (psbt) {
              _log.debug(
                _tag,
                'PSBT ready for review \u2014 asset: ${psbt.asset.ticker}, '
                'amount: ${psbt.satoshi} sats, fees: ${psbt.networkFees} sats',
              );
              return _buildSuccessScreen(
                context,
                psbt,
                bitcoinPrice,
                currencySymbol,
                validationState,
                isDrainTransaction,
              );
            },
          ),
      loading: () {
        _log.debug(_tag, 'Waiting for PSBT to be prepared...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.pop();
        });
        return _buildLoadingScreen(context, isDrainTransaction);
      },
      error: (error, stackTrace) {
        _log.critical(
          _tag,
          'PSBT provider threw an unhandled exception',
          error: error,
          stackTrace: stackTrace,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.pop();
        });
        return _buildErrorScreen(context, error.toString());
      },
    );
  }

  Widget _buildLoadingScreen(
    BuildContext context, [
    bool isDrainTransaction = false,
  ]) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDrainTransaction ? t.wallet_send_all_title : t.wallet_send_title,
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              isDrainTransaction
                  ? t.wallet_send_calculating_total
                  : t.wallet_send_preparing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.wallet_send_title),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_rounded,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                t.wallet_send_prepare_error,
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text(t.common_back),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(
    BuildContext context,
    PartiallySignedTransaction psbt,
    AsyncValue<double> bitcoinPrice,
    String currencySymbol,
    SendValidationState validationState,
    bool isDrainTransaction,
  ) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;
    final t = AppLocalizations.of(context);

    NetworkType networkType;
    switch (psbt.blockchain) {
      case Blockchain.bitcoin:
        networkType = NetworkType.bitcoin;
        break;
      case Blockchain.lightning:
        networkType = NetworkType.lightning;
        break;
      case Blockchain.liquid:
        networkType = NetworkType.liquid;
        break;
    }

    return PlatformSafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isDrainTransaction ? t.wallet_send_all_title : t.wallet_send_title,
          ),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drain transaction info banner
                if (isDrainTransaction) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.wallet_send_all_info,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.1),
                        colorScheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SvgPicture.asset(
                          psbt.asset.iconPath,
                          width: 32,
                          height: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              psbt.asset.name,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Consumer(
                              builder: (context, ref, _) {
                                if (isDrainTransaction &&
                                    (psbt.asset == Asset.btc ||
                                        psbt.asset == Asset.lbtc)) {
                                  return ref
                                      .watch(balanceProvider(psbt.asset))
                                      .when(
                                        data:
                                            (
                                              balanceEither,
                                            ) => balanceEither.fold(
                                              (error) => Text(
                                                t.wallet_send_calc_value_error,
                                                style: context.textTheme.bodyLarge?.copyWith(
                                                  color: context.colors.textSecondary,
                                                ),
                                              ),
                                              (balance) {
                                                final actualDrainAmount =
                                                    balance - psbt.networkFees;
                                                return bitcoinPrice.when(
                                                  data:
                                                      (btcPrice) => Text(
                                                        _formatAmount(
                                                          actualDrainAmount,
                                                          psbt.asset,
                                                          btcPrice,
                                                          currencySymbol,
                                                        ),
                                                        style: context.textTheme.bodyLarge,
                                                      ),
                                                  loading:
                                                      () => Text(
                                                        t.wallet_send_loading_price,
                                                        style: context.textTheme.bodyLarge,
                                                      ),
                                                  error:
                                                      (error, _) => Text(
                                                        _formatAmount(
                                                          actualDrainAmount,
                                                          psbt.asset,
                                                          null,
                                                          currencySymbol,
                                                        ),
                                                        style: context.textTheme.bodyLarge,
                                                      ),
                                                );
                                              },
                                            ),
                                        loading:
                                            () => Text(
                                              t.wallet_send_calculating_value,
                                              style: context.textTheme.bodyLarge?.copyWith(
                                                color: context.colors.textSecondary,
                                              ),
                                            ),
                                        error:
                                            (error, _) => Text(
                                              'Erro ao calcular valor',
                                              style: context.textTheme.bodyLarge?.copyWith(
                                                color: context.colors.textSecondary,
                                              ),
                                            ),
                                      );
                                }

                                return bitcoinPrice.when(
                                  data:
                                      (btcPrice) => Text(
                                        _formatAmount(
                                          psbt.satoshi,
                                          psbt.asset,
                                          btcPrice,
                                          currencySymbol,
                                        ),
                                        style: context.textTheme.bodyLarge?.copyWith(
                                          color: context.colors.textSecondary,
                                        ),
                                      ),
                                  loading:
                                      () => Text(
                                        t.wallet_send_loading_price,
                                        style: context.textTheme.bodyLarge?.copyWith(
                                          color: context.colors.textSecondary,
                                        ),
                                      ),
                                  error:
                                      (error, _) => Text(
                                        _formatAmount(
                                          psbt.satoshi,
                                          psbt.asset,
                                          null,
                                          currencySymbol,
                                        ),
                                        style: context.textTheme.bodyLarge?.copyWith(
                                          color: context.colors.textSecondary,
                                        ),
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Icon(
                      Icons.hub_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.wallet_send_destination_network,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const NetworkIndicatorWidget(),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.wallet_send_destination_address,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CopyButton(textToCopy: psbt.destination),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.wallet_send_fee_details,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFeeDetails(
                  context,
                  psbt.asset,
                  networkType,
                  psbt.satoshi,
                  psbt.networkFees,
                ),

                if (validationState.errors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t.wallet_send_dust_warning,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 20),

                SlideToConfirmButton(
                  text: t.common_confirm,
                  onSlideComplete:
                      () => _confirmTransaction(context, ref, psbt),
                  isLoading: _isConfirming,
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeeDetails(
    BuildContext context,
    Asset asset,
    NetworkType networkType,
    BigInt amount,
    BigInt networkFees,
  ) {
    final colorScheme = context.colorScheme;
    final t = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildFeeRow(
            context,
            t.wallet_send_network_fee,
            _formatNetworkFee(networkFees, asset),
          ),
          const SizedBox(height: 12),
          _buildFeeRow(context, t.wallet_send_service_fee, _getServiceFee(asset, context)),
          const SizedBox(height: 12),
          Divider(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          _buildFeeRow(
            context,
            t.wallet_send_total_fees,
            _formatNetworkFee(networkFees, asset),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  String _getServiceFee(Asset asset, BuildContext context) {
    final t = AppLocalizations.of(context);
    switch (asset) {
      case Asset.btc || Asset.lbtc:
        return t.wallet_send_free;
      case Asset.usdt:
      case Asset.depix:
        return t.wallet_send_free;
    }
  }

  String _formatAmount(
    BigInt amountInSats,
    Asset asset,
    double? bitcoinPrice,
    String currencySymbol,
  ) {
    if (asset != Asset.btc && asset != Asset.lbtc) {
      final value = amountInSats.toDouble() / 100000000;
      final formattedValue = value
          .toStringAsFixed(8)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
      return "$formattedValue ${asset.ticker}";
    }

    final btcAmount = amountInSats.toDouble() / 100000000;
    final satText = amountInSats == BigInt.one ? 'sat' : 'sats';

    String result = "${btcAmount.toStringAsFixed(8)} BTC";
    result += " ($amountInSats $satText)";

    if (bitcoinPrice != null && bitcoinPrice > 0) {
      final fiatValue = btcAmount * bitcoinPrice;
      result += "\n≈ $currencySymbol ${fiatValue.toStringAsFixed(2)}";
    }

    return result;
  }

  String _formatNetworkFee(BigInt networkFees, Asset asset) {
    if (asset == Asset.btc || asset == Asset.lbtc) {
      if (networkFees == BigInt.zero) {
        return AppLocalizations.of(context).wallet_send_free;
      }
      final satText = networkFees == BigInt.one ? 'sat' : 'sats';
      return "$networkFees $satText";
    } else {
      if (networkFees == BigInt.zero) {
        return AppLocalizations.of(context).wallet_send_free;
      }
      final lbtcAmount = networkFees.toDouble() / 100000000;
      return "${lbtcAmount.toStringAsFixed(8)} L-BTC";
    }
  }

  void _confirmTransaction(
    BuildContext context,
    WidgetRef ref,
    PartiallySignedTransaction psbt,
  ) async {
    if (_isConfirming) {
      _log.debug(_tag, 'Confirm transaction ignored: already confirming');
      return;
    }

    _log.info(
      _tag,
      'User confirmed transaction — asset: ${psbt.asset.ticker}, '
      'amount: ${psbt.satoshi} sats, network: ${psbt.blockchain.name}, '
      'destination: ${psbt.destination.substring(0, psbt.destination.length.clamp(0, 14))}...',
    );

    setState(() {
      _isConfirming = true;
    });

    try {
      _log.debug(_tag, 'Fetching wallet controller to broadcast transaction');
      final walletControllerResult = await ref.read(
        walletControllerProvider.future,
      );

      final result = await walletControllerResult.fold(
        (error) async {
          _log.error(
            _tag,
            'Wallet controller unavailable: ${error.description}',
          );
          return left<String, dynamic>(
            AppLocalizations.of(
              context,
            ).wallet_send_wallet_error(error.description),
          );
        },
        (controller) async =>
            await controller.confirmTransaction(psbt: psbt).run(),
      );

      result.fold(
        (error) {
          _log.error(_tag, 'Transaction broadcast failed: $error');
          _showErrorDialog(context, error);
        },
        (transaction) {
          _log.info(
            _tag,
            'Transaction broadcast successful — asset: ${psbt.asset.ticker}, '
            'amount: ${psbt.satoshi} sats, network: ${psbt.blockchain.name}',
          );
          // Phase 2.3.3: routes through V2 `RefreshWalletUseCase(light)`.
          // Fire-and-forget — failure to refresh is not a send failure
          // (the broadcast already succeeded); orchestrator's tx
          // stream + periodic ticker reconcile UI state on the next
          // emission.
          Future<void>.microtask(() async {
            try {
              final useCase = await ref.read(refreshWalletProvider.future);
              await useCase(strategy: SyncStrategy.light);
            } catch (_) {
              // Swallowed by design.
            }
          });
          _showSuccessScreen(context, psbt);
        },
      );
    } catch (e, stackTrace) {
      _log.critical(
        _tag,
        'Unexpected error during transaction confirmation',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        _showErrorDialog(
          context,
          AppLocalizations.of(context).error_unexpected(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder:
          (context) {
            final textTheme = context.textTheme;
            final colorScheme = context.colorScheme;
            final t = AppLocalizations.of(context);

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_rounded, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Text(t.wallet_send_tx_error_title),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.wallet_send_tx_error_desc,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      error,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.wallet_send_tx_error_check,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.common_ok),
                ),
              ],
            );
          },
    );
  }

  void _showSuccessScreen(
    BuildContext context,
    PartiallySignedTransaction psbt,
  ) {
    TransactionSentScreen.show(
      context,
      asset: psbt.asset,
      amount: psbt.satoshi,
      destinationAddress: psbt.destination,
    );
  }
}
