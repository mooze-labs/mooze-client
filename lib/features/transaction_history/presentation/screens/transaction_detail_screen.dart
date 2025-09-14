import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/utils/formatters.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    final isReceive = widget.transaction.type == TransactionType.receive;
    final amountStr =
        "${isReceive ? '+' : '-'}${(widget.transaction.amount.toDouble() / 100000000).toStringAsFixed(8)}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Transação'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTransactionHeader(amountStr, isReceive),

            const SizedBox(height: 32),

            // Card com detalhes
            _buildDetailsCard(context),

            const SizedBox(height: 24),

            // Botões de ação
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHeader(String amountStr, bool isReceive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Ícone do asset
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: SvgPicture.asset(
              widget.transaction.asset.iconPath,
              width: 48,
              height: 48,
            ),
          ),

          const SizedBox(height: 16),

          // Valor da transação
          Text(
            '$amountStr ${widget.transaction.asset.ticker}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isReceive ? Colors.green : Colors.red,
            ),
          ),

          const SizedBox(height: 8),

          // Tipo da transação
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getTransactionTypeLabel(),
              style: TextStyle(
                color: _getStatusColor(),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações da Transação',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          _buildDetailRow('Status', _getStatusLabel(), _getStatusColor()),
          _buildDetailRow(
            'Data',
            _formatDateTime(widget.transaction.createdAt),
          ),
          _buildDetailRow('Moeda', widget.transaction.asset.name),
          _buildDetailRow(
            'Valor',
            '${(widget.transaction.amount.toDouble() / 100000000).toStringAsFixed(8)} ${widget.transaction.asset.ticker}',
          ),
          _buildDetailRow(
            'ID da Transação',
            truncateHashId(widget.transaction.id),
            null,
            true,
          ),
          _buildDetailRow('Blockchain', _getBlockchainLabel()),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, [
    Color? valueColor,
    bool copyable = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _copyToClipboard(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:
                            _isCopied ? Colors.green : AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        _isCopied ? Icons.check : Icons.copy,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        PrimaryButton(text: 'Ver no Explorer', onPressed: _openInExplorer),
        const SizedBox(height: 24),
      ],
    );
  }

  String _getTransactionTypeLabel() {
    switch (widget.transaction.type) {
      case TransactionType.send:
        return 'Envio';
      case TransactionType.receive:
        return 'Recebimento';
      case TransactionType.swap:
        return 'Swap';
    }
  }

  String _getStatusLabel() {
    switch (widget.transaction.status) {
      case TransactionStatus.pending:
        return 'Pendente';
      case TransactionStatus.confirmed:
        return 'Confirmada';
      case TransactionStatus.failed:
        return 'Falhou';
      case TransactionStatus.refundable:
        return 'Reembolsável';
    }
  }

  String _getBlockchainLabel() {
    switch (widget.transaction.blockchain) {
      case Blockchain.bitcoin:
        return 'Bitcoin';
      case Blockchain.lightning:
        return 'Lightning Network';
      case Blockchain.liquid:
        return 'Liquid Network';
    }
  }

  Color _getStatusColor() {
    switch (widget.transaction.status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.confirmed:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.refundable:
        return Colors.blue;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    return formatter.format(dateTime);
  }

  void _copyToClipboard(String text) {
    // Copia o ID completo, não o truncado
    Clipboard.setData(ClipboardData(text: widget.transaction.id));

    setState(() {
      _isCopied = true;
    });

    // Volta ao estado normal após 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  Future<void> _openInExplorer() async {
    String explorerUrl;
    switch (widget.transaction.asset.id) {
      case 'bitcoin':
        explorerUrl = 'https://blockstream.info/tx/${widget.transaction.id}';
        break;
      case 'tether':
        explorerUrl =
            'https://blockstream.info/liquid/tx/${widget.transaction.id}';
        break;
      case 'depix':
        explorerUrl =
            'https://blockstream.info/liquid/tx/${widget.transaction.id}';
        break;
      default:
        explorerUrl = 'https://blockstream.info/tx/${widget.transaction.id}';
        break;
    }

    final Uri url = Uri.parse(explorerUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
