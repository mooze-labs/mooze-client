import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/v2_legacy_transactions_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/pending_swap_item.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/utils/transaction_formatters.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class TransactionList extends ConsumerWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(v2LegacyTransactionsProvider);
    final isVisible = ref.watch(isVisibleProvider);
    final pendingSwaps = ref.watch(pendingSwapsProvider);
    // Side-effect provider — drops optimistic rows once the persisted
    // store catches up. Watching here keeps the listener alive for
    // the lifetime of the home screen.
    ref.watch(pendingSwapsReconciliationProvider);

    return transactionsAsync.when(
      loading: () => pendingSwaps.isEmpty
          ? const LoadingTransactionList()
          : _TransactionListBody(
              transactions: const [],
              pendingSwaps: pendingSwaps,
              isVisible: isVisible,
            ),
      error: (err, _) => pendingSwaps.isEmpty
          ? const ErrorTransactionList()
          : _TransactionListBody(
              transactions: const [],
              pendingSwaps: pendingSwaps,
              isVisible: isVisible,
            ),
      data: (transactions) => _TransactionListBody(
        transactions: transactions,
        pendingSwaps: pendingSwaps,
        isVisible: isVisible,
      ),
    );
  }
}

class _TransactionListBody extends StatelessWidget {
  final List<Transaction> transactions;
  final List<PendingSwap> pendingSwaps;
  final bool isVisible;

  const _TransactionListBody({
    required this.transactions,
    required this.pendingSwaps,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    // While an optimistic peg-in/out row is alive, hide the raw send
    // leg that belongs to it from the persisted list — otherwise the
    // user briefly sees two rows for the same operation (the
    // animated optimistic card + a plain "BTC sent" / "LBTC sent"
    // entry) for the ~minutes-to-hours gap between the lockup tx
    // appearing and the unifier pairing both legs.
    final filtered = _hideInFlightLegs(transactions, pendingSwaps);

    if (pendingSwaps.isEmpty && filtered.isEmpty) {
      return const EmptyTransactionList();
    }

    return Column(
      children: [
        for (final swap in pendingSwaps) PendingSwapItem(swap: swap),
        if (filtered.isNotEmpty)
          SuccessfulTransactionList(
            transactions: filtered,
            isVisible: isVisible,
          ),
      ],
    );
  }
}

List<Transaction> _hideInFlightLegs(
  List<Transaction> persisted,
  List<PendingSwap> pendingSwaps,
) {
  if (pendingSwaps.isEmpty || persisted.isEmpty) return persisted;

  final lockupTxIds = <String>{};
  for (final p in pendingSwaps) {
    final id = p.breezTxId;
    if (id != null) lockupTxIds.add(id);
  }
  if (lockupTxIds.isEmpty) return persisted;

  return [
    for (final t in persisted)
      if (!lockupTxIds.contains(t.id) &&
          !(t.sendTxId != null && lockupTxIds.contains(t.sendTxId)) &&
          !(t.receiveTxId != null && lockupTxIds.contains(t.receiveTxId)))
        t,
  ];
}

class SuccessfulTransactionList extends ConsumerWidget {
  final List<Transaction> transactions;
  final bool isVisible;

  const SuccessfulTransactionList({
    super.key,
    required this.transactions,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return EmptyTransactionList();
    }

    final t = AppLocalizations.of(context);

    return Column(
      children:
          transactions.map((transaction) {
            final amountStr = TransactionValueFormatter.formatTransactionValue(
              transaction: transaction,
            );
            return GestureDetector(
              onTap: () {
                context.push('/transactions/details', extra: transaction);
              },
              child: HomeTransactionItem(
                icon: transaction.asset.iconPath,
                title: _getTransactionTitle(t, transaction),
                subtitle: _getTransactionSubtitle(t, transaction),
                value: amountStr,
                time: _formatTime(transaction),
                isVisible: isVisible,
                transaction: transaction,
              ),
            );
          }).toList(),
    );
  }

  String _getTransactionTitle(AppLocalizations t, Transaction transaction) {
    if (transaction.fromAsset != null &&
        transaction.toAsset != null &&
        transaction.sentAmount != null &&
        transaction.receivedAmount != null) {
      // Same-asset swap = a refunded peg attempt: the conversion
      // never completed; the funds came back (minus the swap-service
      // refund fee). Render it as a refund instead of as a regular
      // swap so the user can tell at a glance.
      if (transaction.fromAsset == transaction.toAsset) {
        return 'Refunded ${transaction.asset.ticker} swap';
      }
      return t.wallet_tx_swap_pair(
        transaction.fromAsset!.ticker,
        transaction.toAsset!.ticker,
      );
    }

    if (transaction.type == TransactionType.send &&
        transaction.asset == Asset.usdt) {
      return t.wallet_tx_sent(transaction.asset.ticker);
    }

    if (transaction.type == TransactionType.receive &&
        transaction.asset == Asset.lbtc) {
      return t.wallet_tx_received(transaction.asset.ticker);
    }

    switch (transaction.type) {
      case TransactionType.send:
        return t.wallet_tx_sent(transaction.asset.ticker);
      case TransactionType.receive:
        return t.wallet_tx_received(transaction.asset.ticker);
      case TransactionType.swap:
        return t.wallet_tx_swap_pair(
          transaction.fromAsset!.ticker,
          transaction.toAsset!.ticker,
        );
      case TransactionType.submarine:
        return t.wallet_tx_swap_pair(
          transaction.fromAsset!.ticker,
          transaction.toAsset!.ticker,
        );
      case TransactionType.redeposit:
        return t.wallet_tx_redeposit(transaction.asset.ticker);
      case TransactionType.unknown:
        return t.wallet_tx_unknown;
    }
  }

  String _getTransactionSubtitle(AppLocalizations t, Transaction transaction) {
    return _getStatusText(t, transaction.status);
  }

  String _getStatusText(AppLocalizations t, TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return t.tx_status_pending;
      case TransactionStatus.confirmed:
        return t.tx_status_confirmed;
      case TransactionStatus.failed:
        return t.tx_status_failed;
      case TransactionStatus.refundable:
        return t.tx_status_refundable;
    }
  }

  String _formatTime(Transaction transaction) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(transaction.createdAt);
  }
}

class LoadingTransactionList extends StatelessWidget {
  const LoadingTransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = context.colors.baseColor;
    final highlightColor = context.colors.highlightColor;

    return Column(
      children: List.generate(
        3,
        (index) => Container(
          padding: EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorTransactionList extends StatelessWidget {
  const ErrorTransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.grey, size: 48),
          SizedBox(height: 12),
          Text(
            t.wallet_tx_load_error_title,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            t.wallet_tx_load_error_retry,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class EmptyTransactionList extends StatelessWidget {
  const EmptyTransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            color: Colors.blueGrey[200],
            size: 56,
          ),
          const SizedBox(height: 18),
          Text(
            t.wallet_tx_empty_title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            t.wallet_tx_empty_body,
            style: TextStyle(fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class HomeTransactionItem extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String value;
  final String time;
  final bool isVisible;
  final Transaction? transaction;

  const HomeTransactionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.time,
    required this.isVisible,
    this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isSwapByType = transaction?.type == TransactionType.swap;
    final isSubmarineSwap = transaction?.type == TransactionType.submarine;
    final isSwapByData =
        transaction?.fromAsset != null &&
        transaction?.toAsset != null &&
        transaction?.sentAmount != null &&
        transaction?.receivedAmount != null;

    final isSwap = isSwapByType || isSwapByData;
    final hasSwapDetails =
        (isSwap || isSubmarineSwap) &&
        transaction?.fromAsset != null &&
        transaction?.toAsset != null;

    final shouldHideValue =
        isSwap &&
        (transaction?.status == TransactionStatus.refundable ||
            transaction?.status == TransactionStatus.failed);

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          if (hasSwapDetails)
            _buildSwapIcon()
          else
            SvgPicture.asset(icon, width: 50, height: 50),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                SizedBox(height: 4),
                if (hasSwapDetails)
                  _buildSwapSubtitle(context)
                else
                  Text(subtitle, style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                shouldHideValue
                    ? ''
                    : isSwap
                    ? ''
                    : isVisible
                    ? '•••••••'
                    : value,
                style: TextStyle(
                  color:
                      isVisible
                          ? null
                          : (value.contains('-') ? Colors.red : null),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(time, style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwapIcon() {
    // Refunded peg: same asset on both sides. Showing two identical
    // BTC icons reads as a bug — render a single asset icon with a
    // small orange refund badge instead.
    final isRefund = transaction!.fromAsset == transaction!.toAsset;
    if (isRefund) {
      return SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SvgPicture.asset(
                  transaction!.fromAsset!.iconPath,
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orangeAccent,
                ),
                child: const Icon(
                  Icons.assignment_return,
                  size: 12,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 5,
            child: SizedBox(
              width: 35,
              height: 35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.5),
                child: SvgPicture.asset(
                  transaction!.fromAsset!.iconPath,
                  width: 31,
                  height: 31,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 5,
            child: SizedBox(
              width: 35,
              height: 35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.5),
                child: SvgPicture.asset(
                  transaction!.toAsset!.iconPath,
                  width: 31,
                  height: 31,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwapSubtitle(BuildContext context) {
    if (transaction?.status == TransactionStatus.refundable ||
        transaction?.status == TransactionStatus.failed) {
      return Text(subtitle, style: TextStyle(fontSize: 14));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle, style: TextStyle(fontSize: 14)),
        if (!isVisible &&
            transaction?.sentAmount != null &&
            transaction?.receivedAmount != null)
          SizedBox(height: 2),
        if (!isVisible &&
            transaction?.sentAmount != null &&
            transaction?.receivedAmount != null)
          Row(
            children: [
              Text(
                _formatSwapAmount(
                  transaction!.fromAsset!,
                  transaction!.sentAmount!,
                ),
                style: TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(width: 4),
              SvgPicture.asset(
                "assets/icons/menu/navigation/swap.svg",
                width: 12,
                height: 12,
                color: context.colors.primaryColor,
              ),
              SizedBox(width: 4),
              Text(
                _formatSwapAmount(
                  transaction!.toAsset!,
                  transaction!.receivedAmount!,
                ),
                style: TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
      ],
    );
  }

  String _formatSwapAmount(Asset asset, BigInt amount) {
    if (asset == Asset.usdt) {
      final usdtAmount = amount.toDouble() / 100000000;
      return "\$${usdtAmount.toStringAsFixed(2)}";
    }

    if (asset == Asset.depix) {
      final depixAmount = amount.toDouble() / 100000000;
      return "R\$${depixAmount.toStringAsFixed(2)}";
    }

    return asset.formatBalance(amount);
  }
}
