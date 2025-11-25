import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/utils/transaction_formatters.dart';

class TransactionList extends ConsumerWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedTransactionHistory = ref.watch(
      cachedTransactionHistoryProvider,
    );
    final isVisible = ref.watch(isVisibleProvider);

    if (cachedTransactionHistory == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(transactionHistoryCacheProvider.notifier)
            .fetchTransactionsInitial();
      });
      return LoadingTransactionList();
    }

    return cachedTransactionHistory.fold(
      (err) => ErrorTransactionList(),
      (transactions) => SuccessfulTransactionList(
        transactions: transactions,
        isVisible: isVisible,
      ),
    );
  }
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
                title: _getTransactionTitle(transaction),
                subtitle: _getTransactionSubtitle(transaction),
                value: amountStr,
                time: _formatTime(transaction),
                isVisible: isVisible,
                transaction: transaction,
              ),
            );
          }).toList(),
    );
  }

  String _getTransactionTitle(Transaction transaction) {
    if (transaction.fromAsset != null &&
        transaction.toAsset != null &&
        transaction.sentAmount != null &&
        transaction.receivedAmount != null) {
      return "Swap: ${transaction.fromAsset!.ticker} para ${transaction.toAsset!.ticker}";
    }

    if (transaction.type == TransactionType.send &&
        transaction.asset == Asset.usdt) {
      return "Enviou ${transaction.asset.ticker}";
    }

    if (transaction.type == TransactionType.receive &&
        transaction.asset == Asset.lbtc) {
      return "Recebeu ${transaction.asset.ticker}";
    }

    switch (transaction.type) {
      case TransactionType.send:
        return "Enviou ${transaction.asset.ticker}";
      case TransactionType.receive:
        return "Recebeu ${transaction.asset.ticker}";
      case TransactionType.swap:
        return "Swap: ${transaction.asset.ticker}";
      case TransactionType.submarine:
        return "Swap de rede: ${transaction.asset.ticker}";
      case TransactionType.redeposit:
        return "Autodepositou ${transaction.asset.ticker}";
      case TransactionType.unknown:
        return "Unknown transaction type";
    }
  }

  String _getTransactionSubtitle(Transaction transaction) {
    return _getStatusText(transaction.status);
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return "Pendente";
      case TransactionStatus.confirmed:
        return "Confirmado";
      case TransactionStatus.failed:
        return "Falhou";
      case TransactionStatus.refundable:
        return "Reembolsável";
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
    final baseColor = AppColors.baseColor;
    final highlightColor = AppColors.highlightColor;

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
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.grey, size: 48),
          SizedBox(height: 12),
          Text(
            "Unable to load transactions",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            "Please try again later",
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
            "Nenhuma transação encontrada",
            style: TextStyle(
              color: Colors.blueGrey[100],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Seu histórico de transações aparecerá aqui assim que você realizar alguma movimentação.",
            style: TextStyle(color: Colors.grey[400], fontSize: 15),
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
    final isSwapByData =
        transaction?.fromAsset != null &&
        transaction?.toAsset != null &&
        transaction?.sentAmount != null &&
        transaction?.receivedAmount != null;

    final isSwap = isSwapByType || isSwapByData;
    final hasSwapDetails =
        isSwap &&
        transaction?.fromAsset != null &&
        transaction?.toAsset != null;

    return Container(
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
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                // Subtitle especial para swaps
                if (hasSwapDetails)
                  _buildSwapSubtitle()
                else
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isSwap
                    ? ''
                    : isVisible
                    ? '•••••••'
                    : value,
                style: TextStyle(
                  color:
                      isVisible
                          ? Colors.white
                          : (value.contains('-') ? Colors.red : Colors.white),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwapIcon() {
    return Container(
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
          // Asset TO (frente, maior)
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

  Widget _buildSwapSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
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
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(width: 4),
              SvgPicture.asset(
                "assets/icons/menu/navigation/swap.svg",
                width: 12,
                height: 12,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 4),
              Text(
                _formatSwapAmount(
                  transaction!.toAsset!,
                  transaction!.receivedAmount!,
                ),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
