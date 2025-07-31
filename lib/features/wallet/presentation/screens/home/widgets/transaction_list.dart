import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/home/providers/visibility_provider.dart';

class TransactionList extends ConsumerWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionHistory = ref.watch(transactionHistoryProvider);
    final isVisible = ref.watch(isVisibleProvider);
    
    return transactionHistory.when(
      data: (data) => data.fold(
        (err) => ErrorTransactionList(),
        (transactions) => SuccessfulTransactionList(transactions: transactions, isVisible: isVisible)
      ),
      error: (err, stackTrace) => ErrorTransactionList(),
      loading: () => LoadingTransactionList()
    );
  }
}

class SuccessfulTransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final bool isVisible;

  const SuccessfulTransactionList({super.key, required this.transactions, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return EmptyTransactionList();
    }

    return Column(
      children: transactions.map((transaction) {
        final isReceive = transaction.type == TransactionType.receive;
        final amountStr = "${isReceive ? '+' : '-'}${(transaction.amount.toDouble() / 100000000).toStringAsFixed(8)}";
        
        return HomeTransactionItem(
          icon: "assets/images/logos/${transaction.asset.name.toLowerCase()}.png",
          title: _getTransactionTitle(transaction),
          subtitle: _getTransactionSubtitle(transaction),
          value: amountStr,
          time: _formatTime(transaction),
          isVisible: isVisible,
        );
      }).toList(),
    );
  }

  String _getTransactionTitle(Transaction transaction) {
    switch (transaction.type) {
      case TransactionType.send:
        return "Sent ${transaction.asset.name}";
      case TransactionType.receive:
        return "Received ${transaction.asset.name}";
      case TransactionType.swap:
        return "Swapped ${transaction.asset.name}";
    }
  }

  String _getTransactionSubtitle(Transaction transaction) {
    switch (transaction.status) {
      case TransactionStatus.pending:
        return "Pending";
      case TransactionStatus.confirmed:
        return "Confirmed";
      case TransactionStatus.failed:
        return "Failed";
      case TransactionStatus.refundable:
        return "Refundable";
    }
  }

  String _formatTime(Transaction transaction) {
    final formatter = DateFormat('dd/MM/yy HH:mm');
    return formatter.format(transaction.createdAt);
  }
}

class LoadingTransactionList extends StatelessWidget {
  const LoadingTransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;

    return Column(
      children: List.generate(3, (index) => 
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
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
          Icon(
            Icons.error_outline,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            "Unable to load transactions",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Please try again later",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
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
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.receipt_outlined,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            "No transactions yet",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Your transaction history will appear here",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
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

  const HomeTransactionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.time,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        children: [
          Image.asset(icon, width: 50, height: 50),
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
                isVisible ? "******" : value, // exemplo: "-25.00"
                style: TextStyle(
                  color: isVisible ? Colors.white : (value.contains('-') ? Colors.red : Colors.white),
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
}
