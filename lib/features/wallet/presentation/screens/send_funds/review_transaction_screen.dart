import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
// Phase 2.3.3: hide V2's `balanceProvider` to avoid colliding with the
// legacy `balanceProvider(Asset asset)` family this screen uses
// throughout. Phase 2.7 cleanup migrates the screen to V2's per-asset
// provider and removes the hide directive.
import 'package:mooze_mobile/app/di/v2_providers.dart' hide balanceProvider;
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/balance_provider.dart';
import '../../providers/send_funds/bitcoin_price_provider.dart';
import '../../providers/send_funds/drain_provider.dart';
import '../../providers/send_funds/network_detection_provider.dart';
import '../../providers/send_funds/partially_signed_transaction_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';
import '../../providers/wallet_provider.dart';
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
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isDrainTransaction
                  ? t.wallet_send_calculating_total
                  : t.wallet_send_preparing,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.error.withValues(alpha: 0.10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 28,
                  color: cs.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.wallet_send_prepare_error,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: t.common_back,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final NetworkType networkType = switch (psbt.blockchain) {
      Blockchain.bitcoin => NetworkType.bitcoin,
      Blockchain.lightning => NetworkType.unknown,
      Blockchain.liquid => NetworkType.liquid,
    };

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
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isDrainTransaction) ...[
                      _DrainBanner(),
                      const SizedBox(height: 16),
                    ],
                    _HeroCard(
                      psbt: psbt,
                      networkType: networkType,
                      isDrain: isDrainTransaction,
                      currencySymbol: currencySymbol,
                    ),
                    const SizedBox(height: 16),
                    _DetailsCard(
                      address: psbt.destination,
                      asset: psbt.asset,
                      networkFees: psbt.networkFees,
                      bitcoinPrice: bitcoinPrice,
                      currencySymbol: currencySymbol,
                    ),
                    if (validationState.errors.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _DustWarning(message: t.wallet_send_dust_warning),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
              child: SlideToConfirmButton(
                text: t.common_confirm,
                isLoading: _isConfirming,
                onSlideComplete: () => _confirmTransaction(context, ref, psbt),
              ),
            ),
          ],
        ),
      ),
    );
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
        setState(() => _isConfirming = false);
      }
    }
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) {
        final t = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: cs.surface,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.error.withValues(alpha: 0.12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.error_outline_rounded,
                  color: cs.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.wallet_send_tx_error_title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.wallet_send_tx_error_desc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.error.withValues(alpha: 0.30)),
                ),
                child: Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.error,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.wallet_send_tx_error_check,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.textTertiary,
                ),
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

class _DrainBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final warning = context.appColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: warning, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.wallet_send_all_info,
              style: theme.textTheme.labelMedium?.copyWith(
                color: warning,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  final PartiallySignedTransaction psbt;
  final NetworkType networkType;
  final bool isDrain;
  final String currencySymbol;

  const _HeroCard({
    required this.psbt,
    required this.networkType,
    required this.isDrain,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isBtcLike = psbt.asset == Asset.btc || psbt.asset == Asset.lbtc;
    final isDrainBtcLike = isDrain && isBtcLike;

    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _AssetMedallion(asset: psbt.asset),
          const SizedBox(height: 14),
          Text(
            psbt.asset.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _networkSubtitle(context, networkType),
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _TickerPill(text: psbt.asset.ticker),
          const SizedBox(height: 12),
          if (isDrainBtcLike)
            _DrainHeroAmount(
              asset: psbt.asset,
              networkFees: psbt.networkFees,
              currencySymbol: currencySymbol,
            )
          else
            _StaticHeroAmount(
              asset: psbt.asset,
              amountInSats: psbt.satoshi,
              currencySymbol: currencySymbol,
            ),
        ],
      ),
    );
  }

  static String _networkSubtitle(BuildContext context, NetworkType n) {
    final t = AppLocalizations.of(context);
    return switch (n) {
      NetworkType.bitcoin => t.wallet_onchain_network,
      NetworkType.liquid => t.wallet_send_network_liquid,
      NetworkType.unknown => t.wallet_send_network_unknown,
    };
  }
}

class _AssetMedallion extends StatelessWidget {
  final Asset asset;
  const _AssetMedallion({required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? cs.surfaceContainerHighest : cs.surface,
        border:
            isDark
                ? Border.all(color: cs.onSurface.withValues(alpha: 0.06))
                : null,
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        asset.iconPath,
        width: 36,
        height: 36,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _TickerPill extends StatelessWidget {
  final String text;
  const _TickerPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _StaticHeroAmount extends StatelessWidget {
  final Asset asset;
  final BigInt amountInSats;
  final String currencySymbol;

  const _StaticHeroAmount({
    required this.asset,
    required this.amountInSats,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return _HeroAmountStack(
      asset: asset,
      amountInSats: amountInSats,
      currencySymbol: currencySymbol,
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
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelMedium?.copyWith(
      color: context.colors.textSecondary,
    );

    return ref
        .watch(balanceProvider(asset))
        .when(
          data:
              (either) => either.fold(
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
    final theme = Theme.of(context);
    final isBtcLike = asset == Asset.btc || asset == Asset.lbtc;
    final amount = amountInSats.toDouble() / 100000000;

    final mainStr =
        isBtcLike
            ? amount.toStringAsFixed(8)
            : amount
                .toStringAsFixed(8)
                .replaceAll(RegExp(r'0+$'), '')
                .replaceAll(RegExp(r'\.$'), '');

    final heroText =
        isBtcLike
            ? '${SatsInputFormatter.formatValue(amountInSats.toInt())} sats'
            : '$mainStr ${asset.ticker}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Big hero number. `headlineMedium w700` with tight tracking
        // and tabular figures gives the column-aligned, "this is the
        // amount" focal point.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            heroText,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (isBtcLike) ...[
          const SizedBox(height: 8),
          Text(
            '$mainStr ${asset.ticker}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,##0.00', ref.watch(localeStringProvider));
    final style = theme.textTheme.titleSmall?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final price = ref.watch(
      priceQuotesProvider.select((quotes) => quotes.priceFor(asset)),
    );
    if (price == null || price <= 0) return const SizedBox.shrink();

    final fiat = asset.toUsd(amountInSats, price);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text('$currencySymbol ${formatter.format(fiat)}', style: style),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String address;
  final Asset asset;
  final BigInt networkFees;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _DetailsCard({
    required this.address,
    required this.asset,
    required this.networkFees,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor =
        isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
            : theme.colorScheme.onSurface.withValues(alpha: 0.05);

    return _SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            child: _AddressBlock(address: address),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: _FeeBlock(
              asset: asset,
              networkFees: networkFees,
              bitcoinPrice: bitcoinPrice,
              currencySymbol: currencySymbol,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  final String address;
  const _AddressBlock({required this.address});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.wallet_send_destination_address,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            _InlineCopyButton(text: address),
          ],
        ),
        const SizedBox(height: 6),
        SelectableText(
          address,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            fontSize: 13.5,
            height: 1.45,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _FeeBlock extends StatelessWidget {
  final Asset asset;
  final BigInt networkFees;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _FeeBlock({
    required this.asset,
    required this.networkFees,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  t.wallet_send_network_fee,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: context.colors.textTertiary,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatNetworkFee(context, networkFees, asset),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            _FeeFiatLine(
              asset: asset,
              networkFees: networkFees,
              bitcoinPrice: bitcoinPrice,
              currencySymbol: currencySymbol,
            ),
          ],
        ),
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
}

class _FeeFiatLine extends ConsumerWidget {
  final Asset asset;
  final BigInt networkFees;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _FeeFiatLine({
    required this.asset,
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
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '≈ $currencySymbol ${formatter.format(fiat)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _InlineCopyButton extends StatefulWidget {
  final String text;
  const _InlineCopyButton({required this.text});

  @override
  State<_InlineCopyButton> createState() => _InlineCopyButtonState();
}

class _InlineCopyButtonState extends State<_InlineCopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final positive = context.colors.positiveColor;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _copy,
        customBorder: const CircleBorder(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: SizedBox(
            key: ValueKey(_copied),
            width: 28,
            height: 28,
            child: Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 16,
              color: _copied ? positive : cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Dust / validation warning — same error-tint recipe as the
// `ValidationErrorsWidget` on the editing screen, so the visual
// vocabulary stays consistent across both screens.
// ─────────────────────────────────────────────────────────────────────

class _DustWarning extends StatelessWidget {
  final String message;
  const _DustWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: cs.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.error.withValues(alpha: 0.95),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Soft elevated surface — Coinbase / Cash App vocabulary. Drops the
// hairline border in favour of:
//   • light mode → a very subtle drop shadow, surface fill
//   • dark mode  → a slightly elevated container tier (no shadow,
//     since shadows are invisible on dark scaffolds) + an ultra-thin
//     hairline for definition
//
// 20 radius (vs 16 in the older stat-card recipe) reads more
// premium without crossing into "consumer cute".
// ─────────────────────────────────────────────────────────────────────

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : cs.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            isDark
                ? Border.all(color: cs.onSurface.withValues(alpha: 0.06))
                : null,
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
      ),
      child: child,
    );
  }
}
