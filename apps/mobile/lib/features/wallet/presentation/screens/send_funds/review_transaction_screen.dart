import 'package:mooze_mobile/shared/analytics/events.dart';
import 'package:mooze_mobile/shared/analytics/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
// Phase 2.3.3: hide V2's `balanceProvider` to avoid colliding with the
// legacy `balanceProvider(Asset asset)` family this screen uses
// throughout. Phase 2.7 cleanup migrates the screen to V2's per-asset
// provider and removes the hide directive.
import 'package:mooze_mobile/app/di/v2_providers.dart' hide balanceProvider;
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/balance_provider.dart';
import '../../providers/send_funds/bitcoin_price_provider.dart';
import '../../providers/send_funds/drain_provider.dart';
import '../../providers/send_funds/network_detection_provider.dart';
import '../../providers/send_funds/partially_signed_transaction_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/send_funds/send_flow_parts.dart';
import 'transaction_sent_screen.dart';

/// Review step of a Liquid send.
///
/// The amount is the hero. Below it come the destination with its network
/// badge and one glass panel with the fee. The slide-to-confirm control
/// stays pinned at the bottom.
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
      data: (psbtEither) => psbtEither.fold(
        (error) {
          _log.error(_tag, 'PSBT preparation returned an error: $error');
          _scheduleAutoPop();
          return _buildErrorScreen(context, error);
        },
        (psbt) {
          _log.debug(
            _tag,
            'PSBT ready for review — asset: ${psbt.asset.ticker}, '
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
        _scheduleAutoPop();
        return _buildLoadingScreen(context, isDrainTransaction);
      },
      error: (error, stackTrace) {
        _log.critical(
          _tag,
          'PSBT provider threw an unhandled exception',
          error: error,
          stackTrace: stackTrace,
        );
        _scheduleAutoPop();
        return _buildErrorScreen(context, error.toString());
      },
    );
  }

  void _scheduleAutoPop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) context.pop();
    });
  }

  Widget _buildLoadingScreen(
    BuildContext context, [
    bool isDrainTransaction = false,
  ]) {
    final t = AppLocalizations.of(context);
    return SendStatusScaffold(
      status: PixStatusView(
        kind: PixStatusKind.processing,
        title: isDrainTransaction
            ? t.wallet_send_calculating_total
            : t.wallet_send_preparing,
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    final t = AppLocalizations.of(context);
    return SendStatusScaffold(
      status: PixStatusView(
        kind: PixStatusKind.failure,
        title: t.wallet_send_prepare_error,
        message: error,
      ),
      bottomAction: PrimaryButton(
        text: t.common_back,
        onPressed: () => context.pop(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Success state — the review screen the user actually sees.
  // ─────────────────────────────────────────────────────────────────

  Widget _buildSuccessScreen(
    BuildContext context,
    PartiallySignedTransaction psbt,
    AsyncValue<double> bitcoinPrice,
    String currencySymbol,
    SendValidationState validationState,
    bool isDrainTransaction,
  ) {
    final t = AppLocalizations.of(context);

    final NetworkType networkType = switch (psbt.blockchain) {
      Blockchain.bitcoin => NetworkType.bitcoin,
      Blockchain.lightning => NetworkType.unknown,
      Blockchain.liquid => NetworkType.liquid,
    };

    return SendFlowScaffold(
      title: isDrainTransaction ? t.wallet_send_all_title : t.wallet_send_title,
      bottomAction: SlideToConfirmButton(
        text: t.common_confirm,
        isLoading: _isConfirming,
        onSlideComplete: () => _confirmTransaction(context, ref, psbt),
      ),
      children: [
        if (isDrainTransaction) ...[
          SendNotice(
            icon: PixIcons.info,
            tone: PixTone.warning,
            message: t.wallet_send_all_info,
          ),
          const SizedBox(height: 24),
        ],
        _HeroAmount(
          psbt: psbt,
          isDrain: isDrainTransaction,
          currencySymbol: currencySymbol,
        ),
        const SizedBox(height: 28),
        SendRecipient(
          label: t.wallet_send_destination_address,
          address: psbt.destination,
          network: networkType,
        ),
        const SizedBox(height: 24),
        SendSummaryPanel(
          rows: [
            SendSummaryRow(
              label: t.wallet_send_network_fee,
              value: _formatNetworkFee(context, psbt.networkFees, psbt.asset),
              detail: _FeeFiatLine(
                networkFees: psbt.networkFees,
                bitcoinPrice: bitcoinPrice,
                currencySymbol: currencySymbol,
              ),
            ),
          ],
        ),
        if (validationState.errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          SendNotice(
            icon: PixIcons.warning,
            tone: PixTone.negative,
            message: t.wallet_send_dust_warning,
          ),
        ],
      ],
    );
  }

  static String _formatNetworkFee(
    BuildContext context,
    BigInt fees,
    Asset asset,
  ) {
    final t = AppLocalizations.of(context);
    if (fees == BigInt.zero) return t.wallet_send_free;
    if (asset == Asset.btc || asset == Asset.lbtc) {
      final satText = fees == BigInt.one ? 'sat' : 'sats';
      return '${SatsInputFormatter.formatValue(fees.toInt())} $satText';
    }
    final lbtcAmount = fees;
    return '$lbtcAmount Sats (L-BTC)';
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

    setState(() => _isConfirming = true);
    final analytics = ref.read(analyticsProvider);
    final analyticsChain = psbt.blockchain == Blockchain.bitcoin
        ? 'bitcoin'
        : 'liquid';
    analytics.track(AnalyticsEvent.send('send_started', analyticsChain));
    var outcomeReported = false;

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

      outcomeReported = true;
      result.fold(
        (error) {
          analytics.track(
            AnalyticsEvent.send(
              'send_failed',
              analyticsChain,
              errorCode: 'unknown',
            ),
          );
          _log.error(_tag, 'Transaction broadcast failed: $error');
          _showErrorDialog(context, error);
        },
        (transaction) {
          analytics.track(
            AnalyticsEvent.send('send_submission_succeeded', analyticsChain),
          );
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
          _showSuccessScreen(
            context,
            psbt,
            transaction is Transaction ? transaction.id : null,
          );
        },
      );
    } catch (e, stackTrace) {
      if (!outcomeReported) {
        analytics.track(
          AnalyticsEvent.send(
            'send_failed',
            analyticsChain,
            errorCode: 'unknown',
          ),
        );
      }
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
        setState(() => _isConfirming = false);
      }
    }
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) {
        final t = AppLocalizations.of(context);
        final negative = context.colors.negativeColor;

        return GlassAlertDialog(
          title: Column(
            children: [
              const PixIconWell(
                icon: PixIcons.error,
                tone: PixTone.negative,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                t.wallet_send_tx_error_title,
                textAlign: TextAlign.center,
                style: context.textTheme.titleLarge?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.wallet_send_tx_error_desc,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: negative.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: negative.withValues(alpha: 0.30)),
                  ),
                  child: Text(
                    error,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textPrimary,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.wallet_send_tx_error_check,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.textPrimary,
                minimumSize: const Size(64, 48),
              ),
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
    String? transactionId,
  ) {
    TransactionSentScreen.show(
      context,
      asset: psbt.asset,
      amount: psbt.satoshi,
      destinationAddress: psbt.destination,
      transactionId: transactionId,
    );
  }
}

/// The hero of the review: the asset, the amount, and its fiat value.
class _HeroAmount extends StatelessWidget {
  final PartiallySignedTransaction psbt;
  final bool isDrain;
  final String currencySymbol;

  const _HeroAmount({
    required this.psbt,
    required this.isDrain,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isBtcLike = psbt.asset == Asset.btc || psbt.asset == Asset.lbtc;
    final isDrainBtcLike = isDrain && isBtcLike;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SendAssetLogo(asset: psbt.asset, size: 32),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                psbt.asset.name,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (isDrainBtcLike)
          _DrainHeroAmount(
            asset: psbt.asset,
            networkFees: psbt.networkFees,
            currencySymbol: currencySymbol,
          )
        else
          _HeroAmountStack(
            asset: psbt.asset,
            amountInSats: psbt.satoshi,
            currencySymbol: currencySymbol,
          ),
      ],
    );
  }
}

class _DrainHeroAmount extends ConsumerWidget {
  final Asset asset;
  final BigInt networkFees;
  final String currencySymbol;

  const _DrainHeroAmount({
    required this.asset,
    required this.networkFees,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final muted = context.textTheme.bodyMedium?.copyWith(
      color: context.colors.textSecondary,
    );

    return ref
        .watch(balanceProvider(asset))
        .when(
          data: (either) => either.fold(
            (_) => Text(t.wallet_send_calc_value_error, style: muted),
            (balance) => _HeroAmountStack(
              asset: asset,
              amountInSats: balance - networkFees,
              currencySymbol: currencySymbol,
            ),
          ),
          loading: () => Text(t.wallet_send_calculating_value, style: muted),
          error: (_, _) => Text(t.wallet_send_calc_value_error, style: muted),
        );
  }
}

class _HeroAmountStack extends StatelessWidget {
  final Asset asset;
  final BigInt amountInSats;
  final String currencySymbol;

  const _HeroAmountStack({
    required this.asset,
    required this.amountInSats,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isBtcLike = asset == Asset.btc || asset == Asset.lbtc;
    final amount = amountInSats.toDouble() / 100000000;

    final mainStr = isBtcLike
        ? amount.toStringAsFixed(8)
        : amount
              .toStringAsFixed(8)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BTC-like assets lead with sats, then show the BTC amount below.
        if (isBtcLike)
          SendHeroAmount(
            digits: SatsInputFormatter.formatValue(amountInSats.toInt()),
            unit: 'sats',
          )
        else
          SendHeroAmount(digits: mainStr, unit: asset.ticker),
        if (isBtcLike) SendQuietText('$mainStr ${asset.ticker}'),
        _HeroFiatLine(
          asset: asset,
          amountInSats: amountInSats,
          currencySymbol: currencySymbol,
        ),
      ],
    );
  }
}

class _HeroFiatLine extends ConsumerWidget {
  final Asset asset;
  final BigInt amountInSats;
  final String currencySymbol;

  const _HeroFiatLine({
    required this.asset,
    required this.amountInSats,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat('#,##0.00', ref.watch(localeStringProvider));

    final price = ref.watch(
      priceQuotesProvider.select((quotes) => quotes.priceFor(asset)),
    );
    if (price == null || price <= 0) return const SizedBox.shrink();

    final fiat = asset.toUsd(amountInSats, price);
    return SendQuietText('$currencySymbol ${formatter.format(fiat)}');
  }
}

class _FeeFiatLine extends ConsumerWidget {
  final BigInt networkFees;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _FeeFiatLine({
    required this.networkFees,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fee fiat is only meaningful for BTC-flavoured fees. L-BTC token
    // fees on Liquid (paid in L-BTC for non-BTC assets) can also be
    // converted via the BTC price, so route both through the same
    // computation.
    if (networkFees == BigInt.zero) return const SizedBox.shrink();
    final formatter = NumberFormat('#,##0.00', ref.watch(localeStringProvider));
    return bitcoinPrice.when(
      data: (price) {
        if (price <= 0) return const SizedBox.shrink();
        final fiat = (networkFees.toDouble() / 100000000) * price;
        return SendQuietText(
          '≈ $currencySymbol ${formatter.format(fiat)}',
          textAlign: TextAlign.end,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
