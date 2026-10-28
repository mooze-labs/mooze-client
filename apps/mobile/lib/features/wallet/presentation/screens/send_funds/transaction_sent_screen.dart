import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';

import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/address_controller_provider.dart';
import '../../providers/send_funds/amount_provider.dart';
import '../../providers/send_funds/amount_controller_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../widgets/send_funds/send_flow_parts.dart';

/// Success step of a send.
///
/// The success emblem, the title, and the sent amount form the hero. Below
/// them, copy fields hold the destination and, when known, the transaction
/// ID. One button leads back home.
class TransactionSentScreen extends ConsumerStatefulWidget {
  final Asset asset;
  final BigInt amount;
  final String destinationAddress;

  /// ID of the broadcast transaction. The screen hides its copy field when
  /// it is null.
  final String? transactionId;

  const TransactionSentScreen({
    super.key,
    required this.asset,
    required this.amount,
    required this.destinationAddress,
    this.transactionId,
  });

  static void show(
    BuildContext context, {
    required Asset asset,
    required BigInt amount,
    required String destinationAddress,
    String? transactionId,
  }) {
    // The screen rises from the bottom. With reduced motion it appears at
    // once.
    final duration = Motion.of(context, Motion.durationEmphasis);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => TransactionSentScreen(
          asset: asset,
          amount: amount,
          destinationAddress: destinationAddress,
          transactionId: transactionId,
        ),
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Motion.curveLargeMove,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  ConsumerState<TransactionSentScreen> createState() =>
      _TransactionSentScreenState();
}

class _TransactionSentScreenState extends ConsumerState<TransactionSentScreen> {
  @override
  void initState() {
    super.initState();
    _refreshBalances();
  }

  /// Updates balances after successful send.
  ///
  /// Phase 2.3.3: routes through V2 `RefreshWalletUseCase(strategy: light)`
  /// instead of legacy `walletDataManager.refreshWalletData`. The 1s
  /// pre-delay is preserved (gives the broadcast tx a head start to
  /// surface in the next sync's `listPayments` walk). Fire-and-forget —
  /// failure to refresh is not a send failure (the broadcast already
  /// succeeded); the orchestrator's tx stream + periodic ticker
  /// reconcile UI state on the next emission.
  void _refreshBalances() {
    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return;
      try {
        final useCase = await ref.read(refreshWalletProvider.future);
        await useCase(strategy: SyncStrategy.light);
      } catch (_) {
        // Swallowed by design.
      }
    });
  }

  /// Returns the sent amount as its digits and its unit.
  ///
  /// BTC and L-BTC below 1 BTC show in sats. Other amounts show with 8
  /// decimals and the ticker.
  (String, String) _formatAmount() {
    const decimalPlaces = 8;
    final divisor = BigInt.from(10).pow(decimalPlaces);
    final value = widget.amount.toDouble() / divisor.toDouble();

    // For BTC/LBTC show in sats if value is small
    if ((widget.asset == Asset.btc || widget.asset == Asset.lbtc) &&
        widget.amount < BigInt.from(100000000)) {
      return ('${widget.amount}', 'sats');
    }

    return (value.toStringAsFixed(decimalPlaces), widget.asset.ticker);
  }

  void _handleClose() {
    // Clear the TextEditingControllers
    ref.read(addressControllerProvider).clear();
    ref.read(amountControllerProvider).clear();

    // Clear the StateProviders
    ref.read(addressStateProvider.notifier).state = '';
    ref.read(amountStateProvider.notifier).state = 0;
    ref.read(formattedAmountProvider.notifier).state = '0';
    ref.read(selectedAssetProvider.notifier).state = Asset.lbtc;

    // Clear validation
    ref.read(sendValidationControllerProvider.notifier).clearValidation();

    // Navigate to home
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (digits, unit) = _formatAmount();
    final transactionId = widget.transactionId;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleClose();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: AppBackdrop()),
            SafeArea(
              child: SendEntrance(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PixStatusView(
                                kind: PixStatusKind.success,
                                title: t.tx_sent_title,
                                message: t.tx_sent_subtitle(
                                  widget.asset.ticker,
                                ),
                                child: _SentAmount(digits: digits, unit: unit),
                              ),
                              const SizedBox(height: 32),
                              PixCopyField(
                                label: t.wallet_send_destination_address,
                                value: widget.destinationAddress,
                                icon: PixIcons.send,
                              ),
                              if (transactionId != null &&
                                  transactionId.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                PixCopyField(
                                  label: t.tx_id,
                                  value: transactionId,
                                  icon: PixIcons.receipt,
                                ),
                              ],
                              const SizedBox(height: 20),
                              Text(
                                t.tx_sent_track_history,
                                textAlign: TextAlign.center,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: PrimaryButton(
                        text: t.refund_success_back_dashboard,
                        onPressed: _handleClose,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Sent" caption and the sent amount, centered under the title.
class _SentAmount extends StatelessWidget {
  const _SentAmount({required this.digits, required this.unit});

  final String digits;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final muted = context.colors.textSecondary;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixIcon(PixIcons.send, size: 16, color: muted),
            const SizedBox(width: 6),
            Text(
              t.tx_sent_status_label,
              style: context.textTheme.labelLarge?.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SendHeroAmount(digits: digits, unit: unit, alignment: Alignment.center),
      ],
    );
  }
}
