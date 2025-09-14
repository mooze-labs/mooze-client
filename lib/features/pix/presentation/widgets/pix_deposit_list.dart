import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class PixDepositList extends StatelessWidget {
  final List<PixDeposit> deposits;
  final bool isVisible;
  final VoidCallback? onRefresh;

  const PixDepositList({
    super.key,
    required this.deposits,
    required this.isVisible,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (deposits.isEmpty) {
      return const EmptyPixDepositList();
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: deposits.length,
        itemBuilder: (context, index) {
          return PixDepositListItem(
            deposit: deposits[index],
            isVisible: isVisible,
          );
        },
      ),
    );
  }
}

class PixDepositListItem extends StatelessWidget {
  final PixDeposit deposit;
  final bool isVisible;

  const PixDepositListItem({
    super.key,
    required this.deposit,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/depix/transactions/details', extra: deposit);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SvgPicture.asset(deposit.asset.iconPath, width: 50, height: 50),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPixDepositTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPixDepositSubtitle(),
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isVisible
                      ? '•••••••'
                      : '+R\$ ${_formatAmount(deposit.amountInCents)}',
                  style: TextStyle(
                    color: isVisible ? Colors.white : _getStatusColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(deposit.createdAt),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPixDepositTitle() {
    return "Recebido ${deposit.asset.name}";
  }

  String _getPixDepositSubtitle() {
    switch (deposit.status) {
      case DepositStatus.pending:
        return "Pendente";
      case DepositStatus.processing:
        return "Processando";
      case DepositStatus.finished:
        return "Finalizado";
      case DepositStatus.expired:
        return "Expirado";
    }
  }

  String _formatTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  String _formatAmount(int amountInCents) {
    final amount = amountInCents / 100;
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    ).format(amount);
  }

  Color _getStatusColor() {
    switch (deposit.status) {
      case DepositStatus.pending:
        return Colors.orange;
      case DepositStatus.processing:
        return Colors.blue;
      case DepositStatus.finished:
        return Colors.green;
      case DepositStatus.expired:
        return Colors.red;
    }
  }
}

class EmptyPixDepositList extends StatelessWidget {
  const EmptyPixDepositList({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pix, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Nenhum depósito PIX encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seus depósitos PIX aparecerão aqui',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class LoadingPixDepositList extends StatelessWidget {
  const LoadingPixDepositList({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.baseColor;
    final highlightColor = AppColors.highlightColor;

    return Column(
      children: List.generate(
        3,
        (index) => Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
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
              const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
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
                  const SizedBox(height: 4),
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

class ErrorPixDepositList extends StatelessWidget {
  final VoidCallback? onRetry;

  const ErrorPixDepositList({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.grey, size: 48),
          const SizedBox(height: 12),
          const Text(
            "Erro ao carregar depósitos PIX",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Tente novamente mais tarde",
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
