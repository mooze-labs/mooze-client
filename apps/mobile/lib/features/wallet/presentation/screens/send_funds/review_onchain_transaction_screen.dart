import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/address_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/amount_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/bitcoin_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/drain_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/fee_speed_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/prepared_psbt_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/send_flow_parts.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'transaction_sent_screen.dart';

/// Review step of a Bitcoin on-chain send.
///
/// The amount is the hero. Below it come the destination with its network
/// badge and one glass panel with the fee, the fee speed, and the total.
/// The slide-to-confirm control stays pinned at the bottom.
class ReviewOnchainTransactionScreen extends ConsumerStatefulWidget {
  const ReviewOnchainTransactionScreen({super.key});

  @override
  ConsumerState<ReviewOnchainTransactionScreen> createState() =>
      _ReviewOnchainTransactionScreenState();
}

class _ReviewOnchainTransactionScreenState
    extends ConsumerState<ReviewOnchainTransactionScreen> {
  bool _isConfirming = false;

  Future<void> _handleConfirm() async {
    if (_isConfirming) return;

    setState(() => _isConfirming = true);

    try {
      final walletController = await ref.read(walletControllerProvider.future);
      final psbt = ref.read(preparedPsbtProvider);

      if (psbt == null) {
        if (mounted) {
          AppSnackBar.error(
            context,
            AppLocalizations.of(context).wallet_tx_not_found_error,
          );
        }
        return;
      }

      await walletController.match(
        (error) async {
          if (mounted) {
            AppSnackBar.error(
              context,
              AppLocalizations.of(context).error_generic(error.toString()),
            );
          }
        },
        (controller) async {
          final txResult = await controller
              .confirmTransaction(psbt: psbt)
              .run();

          await txResult.match(
            (error) async {
              if (mounted) {
                AppSnackBar.error(
                  context,
                  AppLocalizations.of(
                    context,
                  ).wallet_send_tx_error(error.toString()),
                );
              }
            },
            (transaction) async {
              Future<void>.microtask(() async {
                try {
                  final useCase = await ref.read(refreshWalletProvider.future);
                  await useCase(strategy: SyncStrategy.light);
                } catch (_) {
                  // Swallowed by design.
                }
              });

              if (mounted) {
                TransactionSentScreen.show(
                  context,
                  asset: psbt.asset,
                  amount: psbt.satoshi,
                  destinationAddress: psbt.destination,
                  transactionId: transaction.id,
                );
              }
            },
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final asset = ref.watch(selectedAssetProvider);
    final finalAmount = ref.watch(finalAmountProvider);
    final isDrainTransaction = ref.watch(isDrainTransactionProvider);
    final destination = ref.watch(addressStateProvider);
    final psbt = ref.watch(preparedPsbtProvider);
    final bitcoinPrice = ref.watch(bitcoinPriceProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (psbt == null) {
      return SendStatusScaffold(
        status: PixStatusView(
          kind: PixStatusKind.failure,
          title: t.wallet_send_prepare_error,
          message: t.wallet_tx_not_found,
        ),
      );
    }

    return _ReviewBody(
      asset: asset,
      amountInSats: finalAmount,
      isDrain: isDrainTransaction,
      destination: destination,
      networkFeeSats: psbt.networkFees,
      bitcoinPrice: bitcoinPrice,
      currencySymbol: currencySymbol,
      isConfirming: _isConfirming,
      onConfirm: _handleConfirm,
    );
  }
}

class _ReviewBody extends StatelessWidget {
  final Asset asset;
  final int amountInSats;
  final bool isDrain;
  final String destination;
  final BigInt networkFeeSats;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;
  final bool isConfirming;
  final Future<void> Function() onConfirm;

  const _ReviewBody({
    required this.asset,
    required this.amountInSats,
    required this.isDrain,
    required this.destination,
    required this.networkFeeSats,
    required this.bitcoinPrice,
    required this.currencySymbol,
    required this.isConfirming,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final feeSats = networkFeeSats.toInt();
    final totalSats = amountInSats + feeSats;

    return SendFlowScaffold(
      title: t.wallet_send_title,
      bottomAction: SlideToConfirmButton(
        text: isConfirming ? t.common_sending : t.wallet_slide_to_confirm,
        isLoading: isConfirming,
        onSlideComplete: isConfirming ? () {} : () => onConfirm(),
      ),
      children: [
        if (isDrain) ...[
          SendNotice(
            icon: PixIcons.info,
            tone: PixTone.warning,
            message: t.wallet_send_all_info,
          ),
          const SizedBox(height: 24),
        ],
        _HeroAmount(
          asset: asset,
          amountInSats: amountInSats,
          bitcoinPrice: bitcoinPrice,
          currencySymbol: currencySymbol,
        ),
        const SizedBox(height: 28),
        SendRecipient(
          label: t.wallet_destination,
          address: destination,
          network: NetworkType.bitcoin,
        ),
        const SizedBox(height: 24),
        Consumer(
          builder: (context, ref, _) {
            final speed = _speedTexts(context, ref.watch(feeSpeedProvider));
            return SendSummaryPanel(
              rows: [
                SendSummaryRow(
                  label: t.wallet_network_fee,
                  value: '$feeSats Sats',
                  detail: _FiatSubLine(
                    amountInSats: feeSats,
                    bitcoinPrice: bitcoinPrice,
                    currencySymbol: currencySymbol,
                  ),
                ),
                SendSummaryRow(
                  label: t.wallet_fee_speed_title,
                  value: speed.$1,
                  detail: SendQuietText(speed.$2, textAlign: TextAlign.end),
                ),
                if (!isDrain)
                  SendSummaryRow(
                    label: t.wallet_total,
                    value: '$totalSats Sats',
                    highlight: true,
                    detail: _FiatSubLine(
                      amountInSats: totalSats,
                      bitcoinPrice: bitcoinPrice,
                      currencySymbol: currencySymbol,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _Footnote(text: t.wallet_fee_calculated_note),
      ],
    );
  }

  /// Returns the name and the description of [speed].
  static (String, String) _speedTexts(BuildContext context, FeeSpeed speed) {
    final t = AppLocalizations.of(context);
    return switch (speed) {
      FeeSpeed.low => (t.wallet_speed_economic, t.wallet_speed_economic_desc),
      FeeSpeed.medium => (t.wallet_speed_normal, t.wallet_speed_normal_desc),
      FeeSpeed.fast => (t.wallet_speed_priority, t.wallet_speed_priority_desc),
    };
  }
}

/// The hero of the review: the asset, the amount, and its fiat value.
class _HeroAmount extends StatelessWidget {
  final Asset asset;
  final int amountInSats;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _HeroAmount({
    required this.asset,
    required this.amountInSats,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isBtcLike = asset == Asset.btc || asset == Asset.lbtc;
    final amount = amountInSats / 100000000;
    final mainStr = isBtcLike
        ? amount.toStringAsFixed(8)
        : amount
              .toStringAsFixed(8)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SendAssetLogo(asset: asset, size: 32),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                asset.name,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SendHeroAmount(
          digits: SatsInputFormatter.formatValue(amountInSats),
          unit: 'sats',
        ),
        if (isBtcLike) SendQuietText('$mainStr ${asset.ticker}'),
        _HeroFiatLine(
          amountInSats: amountInSats,
          bitcoinPrice: bitcoinPrice,
          currencySymbol: currencySymbol,
        ),
      ],
    );
  }
}

class _HeroFiatLine extends StatelessWidget {
  final int amountInSats;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _HeroFiatLine({
    required this.amountInSats,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return bitcoinPrice.when(
      data: (price) {
        if (price <= 0) return const SizedBox.shrink();
        final fiat = (amountInSats / 100000000) * price;
        return SendQuietText('$currencySymbol ${fiat.toStringAsFixed(2)}');
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _FiatSubLine extends StatelessWidget {
  final int amountInSats;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _FiatSubLine({
    required this.amountInSats,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (amountInSats <= 0) return const SizedBox.shrink();
    return bitcoinPrice.when(
      data: (price) {
        if (price <= 0) return const SizedBox.shrink();
        final fiat = (amountInSats / 100000000) * price;
        return SendQuietText(
          '≈ $currencySymbol ${fiat.toStringAsFixed(2)}',
          textAlign: TextAlign.end,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// A quiet note below the summary, after an info icon.
class _Footnote extends StatelessWidget {
  final String text;
  const _Footnote({required this.text});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: PixIcon(PixIcons.info, size: 14, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
