import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/utils/formatters.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/widgets.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  final Map<String, bool> _copiedFields = {};
  int? _currentBlockHeight;

  @override
  void initState() {
    super.initState();
    _fetchCurrentBlockHeight();
  }

  Future<void> _fetchCurrentBlockHeight() async {
    if (widget.transaction.blockchain == Blockchain.bitcoin &&
        widget.transaction.confirmationHeight != null) {
      try {
        final datasourceResult = await ref.read(bdkDatasourceProvider.future);
        await datasourceResult.fold(
          (error) async {
            // Silently fail
          },
          (datasource) async {
            final height = await datasource.blockchain.getHeight();
            if (mounted) {
              setState(() {
                _currentBlockHeight = height;
              });
            }
          },
        );
      } catch (e) {
        // Silently fail
      }
    }
  }

  int? _getConfirmations() {
    if (widget.transaction.confirmationHeight == null ||
        _currentBlockHeight == null) {
      return null;
    }
    return _currentBlockHeight! - widget.transaction.confirmationHeight! + 1;
  }

  @override
  Widget build(BuildContext context) {
    final isReceive = widget.transaction.type == TransactionType.receive;
    final amountStr =
        "${isReceive ? '+' : ''}${(widget.transaction.amount.toDouble() / 100000000).toStringAsFixed(8)}";

    return PlatformSafeArea(
      child: Scaffold(
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

              _buildDetailsCard(context),

              const SizedBox(height: 24),

              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHeader(String amountStr, bool isReceive) {
    final isSwap = widget.transaction.type == TransactionType.swap;

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
          if (isSwap && _hasSwapDetails())
            _buildSwapHeader()
          else
            _buildRegularHeader(amountStr, isReceive),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.2),
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

  Widget _buildRegularHeader(String amountStr, bool isReceive) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: SvgPicture.asset(
            widget.transaction.asset.iconPath,
            width: 48,
            height: 48,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          '$amountStr ${widget.transaction.asset.ticker}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isReceive ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSwapHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Asset FROM
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: SvgPicture.asset(
                      widget.transaction.fromAsset!.iconPath,
                      width: 42,
                      height: 42,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatSwapAmount(
                        widget.transaction.sentAmount!,
                        widget.transaction.fromAsset!,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Icon(
              Icons.swap_horiz_rounded,
              size: 32,
              color: AppColors.primaryColor,
            ),

            const SizedBox(width: 10),

            // Asset TO
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: SvgPicture.asset(
                      widget.transaction.toAsset!.iconPath,
                      width: 42,
                      height: 42,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatSwapAmount(
                        widget.transaction.receivedAmount!,
                        widget.transaction.toAsset!,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          'Swap realizado',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  bool _hasSwapDetails() {
    return widget.transaction.fromAsset != null &&
        widget.transaction.toAsset != null &&
        widget.transaction.sentAmount != null &&
        widget.transaction.receivedAmount != null;
  }

  String _formatSwapAmount(BigInt amount, dynamic asset) {
    final formattedAmount = (amount.toDouble() / 100000000).toStringAsFixed(8);
    final cleanAmount = formattedAmount
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    return '$cleanAmount ${asset.ticker}';
  }

  Widget _buildDetailsCard(BuildContext context) {
    final isSwap = widget.transaction.type == TransactionType.swap;
    final isSubmarineSwap =
        widget.transaction.type == TransactionType.submarine;

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
            'Informações da Transação',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          _buildDetailRow(
            label: 'Status',
            value: _getStatusLabel(),
            valueColor: _getStatusColor(),
          ),

          // Submarine swap explanation
          if (isSubmarineSwap) ...[
            _buildSubmarineSwapExplanation(),
            const SizedBox(height: 16),
          ],
          if (widget.transaction.blockchain == Blockchain.bitcoin &&
              widget.transaction.status == TransactionStatus.confirmed)
            _buildConfirmationRow(),
          _buildDetailRow(
            label: 'Data',
            value: _formatDateTime(widget.transaction.createdAt),
          ),

          ...(isSwap && _hasSwapDetails()
              ? [const SizedBox.shrink()]
              : [_buildRegularDetailsSection()]),

          if (isSwap && _isCrossChainSwap())
            ..._buildCrossChainSwapIds()
          else
            _buildDetailRow(
              label: 'ID da Transação',
              value: truncateHashId(widget.transaction.id),
              copyable: true,
              copyFieldId: 'transaction_id',
              copyValue: widget.transaction.id,
            ),

          if (widget.transaction.blockchain == Blockchain.lightning) ...[
            if (widget.transaction.preimage != null)
              _buildDetailRow(
                label: "Preimagem",
                value: truncateHashId(widget.transaction.preimage!),
                copyable: true,
                copyFieldId: 'preimage',
                copyValue: widget.transaction.preimage!,
              )
            else if (widget.transaction.status == TransactionStatus.pending)
              _buildPreimageWarning(),
          ],

          _buildDetailRow(label: 'Blockchain', value: _getBlockchainLabel()),
        ],
      ),
    );
  }

  Widget _buildRegularDetailsSection() {
    return Column(
      children: [
        _buildDetailRow(label: 'Moeda', value: widget.transaction.asset.name),
        _buildDetailRow(
          label: 'Valor',
          value:
              '${(widget.transaction.amount.toDouble() / 100000000).toStringAsFixed(8)} ${widget.transaction.asset.ticker}',
        ),
      ],
    );
  }

  Widget _buildSubmarineSwapExplanation() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Esta transação representa uma troca de rede, assim que a transação for confirmada, você receberá os fundos na rede de destino. Esse processo pode levar algum tempo dependendo da rede.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreimageWarning() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Preimagem',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Assim que sua transação for confirmada, a preimagem aparecerá em breve',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow() {
    final confirmations = _getConfirmations();
    final isFullyConfirmed = confirmations != null && confirmations >= 6;

    String displayText;
    Color displayColor;

    if (confirmations == null) {
      displayText = 'Verificando...';
      displayColor = Colors.grey;
    } else if (confirmations >= 6) {
      displayText = '6+ confirmações';
      displayColor = Colors.green;
    } else {
      displayText = '$confirmations/6 confirmações';
      displayColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Confirmações',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: displayColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: displayColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFullyConfirmed
                            ? Icons.check_circle
                            : Icons.hourglass_empty,
                        size: 16,
                        color: displayColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displayText,
                        style: TextStyle(
                          color: displayColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
    bool copyable = false,
    String? copyFieldId,
    String? copyValue,
  }) {
    final fieldId = copyFieldId ?? label;
    final isCopied = _copiedFields[fieldId] ?? false;
    final valueToCopy = copyValue ?? value;

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
                    onTap: () => _copyToClipboard(valueToCopy, fieldId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isCopied ? Colors.green : AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        isCopied ? Icons.check : Icons.copy,
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
    final isRefundable =
        widget.transaction.status == TransactionStatus.refundable;

    if (_isCrossChainSwap()) {
      return Column(
        children: [
          PrimaryButton(
            text:
                'Ver Envio no Explorer (${_getBlockchainName(widget.transaction.sendBlockchain!)})',
            onPressed:
                () => _openInExplorer(
                  txId: widget.transaction.sendTxId,
                  blockchain: widget.transaction.sendBlockchain,
                ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text:
                'Ver Recebimento no Explorer (${_getBlockchainName(widget.transaction.receiveBlockchain!)})',
            onPressed:
                () => _openInExplorer(
                  txId: widget.transaction.receiveTxId,
                  blockchain: widget.transaction.receiveBlockchain,
                ),
          ),
          if (isRefundable) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              text: 'Pedir Refund',
              onPressed: () {
                context.push('/transactions/refund', extra: widget.transaction);
              },
            ),
          ],
          const SizedBox(height: 24),
        ],
      );
    }

    return Column(
      children: [
        PrimaryButton(
          text: 'Ver no Explorer',
          onPressed: () => _openInExplorer(),
        ),
        if (isRefundable) ...[
          const SizedBox(height: 12),
          PrimaryButton(
            text: 'Pedir Refund',
            onPressed: () {
              context.push('/transactions/refund', extra: widget.transaction);
            },
          ),
        ],
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
      case TransactionType.redeposit:
        return "Auto-redepósito";
      case TransactionType.submarine:
        return "Troca de rede";
      case TransactionType.unknown:
        return "Desconhecido";
    }
  }

  String _getStatusLabel() {
    switch (widget.transaction.status) {
      case TransactionStatus.pending:
        return 'Pendente';
      case TransactionStatus.confirmed:
        return 'Confirmada';
      case TransactionStatus.failed:
        return 'Em Análise';
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
    if (widget.transaction.type == TransactionType.swap &&
        widget.transaction.status == TransactionStatus.confirmed) {
      return Colors.green;
    }

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

  void _copyToClipboard(String text, String fieldId) {
    Clipboard.setData(ClipboardData(text: text));

    setState(() {
      _copiedFields[fieldId] = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedFields[fieldId] = false;
        });
      }
    });
  }

  Future<void> _openInExplorer({String? txId, Blockchain? blockchain}) async {
    final String explorerUrl;

    if (txId != null && blockchain != null) {
      explorerUrl = switch (blockchain) {
        Blockchain.bitcoin => 'https://blockstream.info/tx/$txId',
        Blockchain.liquid => 'https://blockstream.info/liquid/tx/$txId',
        Blockchain.lightning => 'https://blockstream.info/liquid/tx/$txId',
      };
    } else if (widget.transaction.blockchainUrl != null) {
      explorerUrl = widget.transaction.blockchainUrl!;
    } else {
      final useTxId = txId ?? widget.transaction.id;
      final useBlockchain = blockchain ?? widget.transaction.blockchain;

      explorerUrl = switch (useBlockchain) {
        Blockchain.bitcoin => 'https://blockstream.info/tx/$useTxId',
        Blockchain.liquid => 'https://blockstream.info/liquid/tx/$useTxId',
        Blockchain.lightning => 'https://blockstream.info/liquid/tx/$useTxId',
      };
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
        await Clipboard.setData(ClipboardData(text: explorerUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir o navegador. Link copiado para área de transferência.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  bool _isCrossChainSwap() {
    return widget.transaction.sendTxId != null &&
        widget.transaction.receiveTxId != null &&
        widget.transaction.sendBlockchain != null &&
        widget.transaction.receiveBlockchain != null &&
        widget.transaction.sendBlockchain !=
            widget.transaction.receiveBlockchain;
  }

  List<Widget> _buildCrossChainSwapIds() {
    return [
      _buildDetailRow(
        label:
            'ID Envio (${_getBlockchainName(widget.transaction.sendBlockchain!)})',
        value: truncateHashId(widget.transaction.sendTxId!),
        copyable: true,
        copyFieldId: 'send_tx_id',
        copyValue: widget.transaction.sendTxId!,
      ),
      _buildDetailRow(
        label:
            'ID Recebimento (${_getBlockchainName(widget.transaction.receiveBlockchain!)})',
        value: truncateHashId(widget.transaction.receiveTxId!),
        copyable: true,
        copyFieldId: 'receive_tx_id',
        copyValue: widget.transaction.receiveTxId!,
      ),
    ];
  }

  String _getBlockchainName(Blockchain blockchain) {
    switch (blockchain) {
      case Blockchain.bitcoin:
        return 'Bitcoin';
      case Blockchain.liquid:
        return 'Liquid';
      case Blockchain.lightning:
        return 'Lightning';
    }
  }
}
