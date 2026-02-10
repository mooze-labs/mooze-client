import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

class PixDepositDetailScreen extends StatefulWidget {
  final PixDeposit deposit;

  const PixDepositDetailScreen({super.key, required this.deposit});

  @override
  State<PixDepositDetailScreen> createState() => _PixDepositDetailScreenState();
}

class _PixDepositDetailScreenState extends State<PixDepositDetailScreen> {
  bool _isPixKeyCopied = false;
  bool _isDepositIdCopied = false;
  bool _isTxIdCopied = false;

  @override
  Widget build(BuildContext context) {
    final amountStr = 'R\$ ${_formatAmount(widget.deposit.amountInCents)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Depósito PIX'),
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
            _buildDepositHeader(amountStr),

            const SizedBox(height: 32),

            _buildDetailsCard(context),

            const SizedBox(height: 24),

            if (widget.deposit.blockchainTxid != null)
              _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositHeader(String amountStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(Icons.pix, size: 48, color: AppColors.primaryColor),
          ),

          const SizedBox(height: 16),

          Text(
            amountStr,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusLabel(),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações do Depósito',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          _buildDetailRow('Status', _getStatusLabel(), _getStatusColor()),
          _buildDetailRow('Data', _formatDateTime(widget.deposit.createdAt)),
          _buildDetailRow('Ativo de destino', widget.deposit.asset.name),
          _buildDetailRow('Valor', amountStr),
          _buildDetailRow(
            'Chave PIX',
            _truncateId(widget.deposit.pixKey),
            null,
            true,
            'pixKey',
          ),
          _buildDetailRow(
            'ID do Depósito',
            _truncateId(widget.deposit.depositId),
            null,
            true,
            'depositId',
          ),
          if (widget.deposit.assetAmount != null &&
              widget.deposit.status == DepositStatus.finished) ...[
            _buildDetailRow(
              'Valor recebido',
              '${(widget.deposit.assetAmount!.toDouble() / 100000000).toStringAsFixed(8)} ${widget.deposit.asset.ticker}',
            ),
          ],
          if (widget.deposit.blockchainTxid != null) ...[
            _buildDetailRow(
              'TX ID',
              _truncateId(widget.deposit.blockchainTxid!),
              null,
              true,
              'txId',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, [
    Color? valueColor,
    bool copyable = false,
    String? fieldId,
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
                    onTap:
                        () => _copyToClipboard(
                          label == 'Chave PIX'
                              ? widget.deposit.pixKey
                              : label == 'ID do Depósito'
                              ? widget.deposit.depositId
                              : widget.deposit.blockchainTxid ?? '',
                          fieldId ?? '',
                        ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isCopiedForField(fieldId) ? Icons.check : Icons.copy,
                        size: 16,
                        color:
                            _isCopiedForField(fieldId)
                                ? Colors.green
                                : Colors.grey[400],
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

  String _getStatusLabel() {
    return widget.deposit.status.label;
  }

  Color _getStatusColor() {
    return widget.deposit.status.color;
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
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

  String get amountStr => 'R\$ ${_formatAmount(widget.deposit.amountInCents)}';

  String _truncateId(String id) {
    if (id.length <= 15) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 8)}';
  }

  bool _isCopiedForField(String? fieldId) {
    switch (fieldId) {
      case 'pixKey':
        return _isPixKeyCopied;
      case 'depositId':
        return _isDepositIdCopied;
      case 'txId':
        return _isTxIdCopied;
      default:
        return false;
    }
  }

  void _copyToClipboard(String text, String fieldId) {
    Clipboard.setData(ClipboardData(text: text));

    setState(() {
      switch (fieldId) {
        case 'pixKey':
          _isPixKeyCopied = true;
          break;
        case 'depositId':
          _isDepositIdCopied = true;
          break;
        case 'txId':
          _isTxIdCopied = true;
          break;
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          switch (fieldId) {
            case 'pixKey':
              _isPixKeyCopied = false;
              break;
            case 'depositId':
              _isDepositIdCopied = false;
              break;
            case 'txId':
              _isTxIdCopied = false;
              break;
          }
        });
      }
    });
  }

  Future<void> _openInExplorer() async {
    if (widget.deposit.blockchainTxid == null) return;

    String explorerUrl;
    switch (widget.deposit.asset.id) {
      case 'bitcoin':
        explorerUrl =
            'https://blockstream.info/tx/${widget.deposit.blockchainTxid}';
        break;
      case 'tether':
        explorerUrl =
            'https://blockstream.info/liquid/tx/${widget.deposit.blockchainTxid}';
        break;
      case 'depix':
        explorerUrl =
            'https://blockstream.info/liquid/tx/${widget.deposit.blockchainTxid}';
        break;
      default:
        explorerUrl =
            'https://blockstream.info/tx/${widget.deposit.blockchainTxid}';
        break;
    }

    final Uri url = Uri.parse(explorerUrl);

    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o navegador.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
