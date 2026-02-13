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
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
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
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Detalhes da Transação',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransactionHeader(amountStr, isReceive),
              const SizedBox(height: 20),
              _buildDetailsCard(context),
              const SizedBox(height: 20),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHeader(String amountStr, bool isReceive) {
    final isSwap =
        widget.transaction.type == TransactionType.swap ||
        widget.transaction.type == TransactionType.submarine;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (isSwap && _hasSwapDetails())
            _buildSwapHeader()
          else
            _buildRegularHeader(amountStr, isReceive),
          const SizedBox(height: 16),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
          const SizedBox(width: 6),
          Text(
            _getStatusLabel(),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (widget.transaction.status) {
      case TransactionStatus.pending:
        return Icons.schedule;
      case TransactionStatus.confirmed:
        return Icons.check_circle;
      case TransactionStatus.failed:
        return Icons.error;
      case TransactionStatus.refundable:
        return Icons.refresh;
    }
  }

  Widget _buildRegularHeader(String amountStr, bool isReceive) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.asset(
            widget.transaction.asset.iconPath,
            width: 36,
            height: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _getTransactionTypeLabel(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$amountStr ${widget.transaction.asset.ticker}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isReceive ? Colors.green : Colors.red,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwapHeader() {
    return Column(
      children: [
        Text(
          'Troca entre ativos',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Asset FROM
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: SvgPicture.asset(
                      widget.transaction.fromAsset!.iconPath,
                      width: 32,
                      height: 32,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.swap_horiz_rounded,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            // Asset TO
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: SvgPicture.asset(
                      widget.transaction.toAsset!.iconPath,
                      width: 32,
                      height: 32,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final confirmed = widget.transaction.status == TransactionStatus.confirmed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Submarine swap explanation
          if (isSubmarineSwap && !confirmed) ...[
            _buildSubmarineSwapExplanation(),
            const SizedBox(height: 16),
          ],

          // Confirmations for Bitcoin
          if (widget.transaction.blockchain == Blockchain.bitcoin &&
              widget.transaction.status != TransactionStatus.confirmed)
            _buildConfirmationRow(),

          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Data',
            value: _formatDateTime(widget.transaction.createdAt),
          ),

          ...(isSwap && _hasSwapDetails()
              ? [const SizedBox.shrink()]
              : [
                _buildInfoRow(
                  icon: Icons.monetization_on,
                  label: 'Moeda',
                  value: widget.transaction.asset.name,
                ),
                _buildInfoRow(
                  icon: Icons.account_balance_wallet,
                  label: 'Valor',
                  value:
                      '${(widget.transaction.amount.toDouble() / 100000000).toStringAsFixed(8)} ${widget.transaction.asset.ticker}',
                ),
              ]),

          _buildInfoRow(
            icon: Icons.link,
            label: 'Blockchain',
            value: _getBlockchainLabel(),
          ),

          if (isSwap && _isCrossChainSwap())
            ..._buildCrossChainSwapIds()
          else
            _buildInfoRow(
              icon: Icons.tag,
              label: 'ID da Transação',
              value: truncateHashId(widget.transaction.id),
              copyable: true,
              copyFieldId: 'transaction_id',
              copyValue: widget.transaction.id,
            ),

          if (widget.transaction.blockchain == Blockchain.lightning) ...[
            if (widget.transaction.destination != null)
              _buildInfoRow(
                icon: Icons.qr_code,
                label:
                    widget.transaction.type == TransactionType.send
                        ? "LNURL"
                        : "Invoice",
                value: truncateHashId(widget.transaction.destination!),
                copyable: true,
                copyFieldId: 'destination',
                copyValue: widget.transaction.destination!,
              ),
            if (widget.transaction.preimage != null)
              _buildInfoRow(
                icon: Icons.key,
                label: "Preimagem",
                value: truncateHashId(widget.transaction.preimage!),
                copyable: true,
                copyFieldId: 'preimagem',
                copyValue: widget.transaction.preimage!,
              )
            else if (widget.transaction.status == TransactionStatus.pending)
              _buildPreimageWarning(),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmarineSwapExplanation() {
    final fromAsset = widget.transaction.fromAsset;
    final toAsset = widget.transaction.toAsset;

    String explanation;
    if (fromAsset != null && toAsset != null) {
      if (fromAsset == Asset.btc && toAsset == Asset.lbtc) {
        explanation =
            'Swap de rede: Você enviou ${fromAsset.ticker} e receberá ${toAsset.ticker}. Assim que a transação onchain for confirmada, os fundos aparecerão automaticamente na Liquid Network.';
      } else if (fromAsset == Asset.lbtc && toAsset == Asset.btc) {
        explanation =
            'Swap de rede: Você enviou ${fromAsset.ticker} e receberá ${toAsset.ticker}. Assim que processado, a transação será enviada para a blockchain Bitcoin.';
      } else {
        explanation =
            'Swap de rede: Transação entre diferentes redes. Aguarde a confirmação.';
      }
    } else {
      explanation =
          'Esta transação representa uma troca de rede. Assim que confirmada, você receberá os fundos na rede de destino.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              explanation,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreimageWarning() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.schedule, size: 18, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Preimagem pendente: Assim que sua transação for confirmada, a preimagem aparecerá aqui',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: displayColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: displayColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: displayColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isFullyConfirmed ? Icons.check_circle : Icons.schedule,
                size: 18,
                color: displayColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirmações',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayText,
                    style: TextStyle(
                      color: displayColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool copyable = false,
    String? copyFieldId,
    String? copyValue,
  }) {
    final fieldId = copyFieldId ?? label;
    final isCopied = _copiedFields[fieldId] ?? false;
    final valueToCopy = copyValue ?? value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(valueToCopy, fieldId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isCopied
                            ? Colors.green.withValues(alpha: 0.2)
                            : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCopied ? Icons.check : Icons.copy,
                    size: 16,
                    color:
                        isCopied
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isRefundable =
        widget.transaction.status == TransactionStatus.refundable;

    if (_isCrossChainSwap()) {
      return Column(
        children: [
          _buildActionButton(
            context: context,
            label: 'Ver Envio',
            subtitle: _getBlockchainName(widget.transaction.sendBlockchain!),
            icon: Icons.call_made,
            onPressed:
                () => _openInExplorer(
                  txId: widget.transaction.sendTxId,
                  blockchain: widget.transaction.sendBlockchain,
                ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context: context,
            label: 'Ver Recebimento',
            subtitle: _getBlockchainName(widget.transaction.receiveBlockchain!),
            icon: Icons.call_received,
            onPressed:
                () => _openInExplorer(
                  txId: widget.transaction.receiveTxId,
                  blockchain: widget.transaction.receiveBlockchain,
                ),
          ),
          if (isRefundable) ...[
            const SizedBox(height: 12),
            _buildActionButton(
              context: context,
              label: 'Solicitar Reembolso',
              subtitle: 'Recuperar seus fundos',
              icon: Icons.refresh,
              onPressed: () {
                context.push('/transactions/refund', extra: widget.transaction);
              },
              isDestructive: true,
            ),
          ],
        ],
      );
    }

    return Column(
      children: [
        _buildActionButton(
          context: context,
          label: 'Ver no Explorer',
          subtitle: 'Visualizar na blockchain',
          icon: Icons.open_in_new,
          onPressed: () => _openInExplorer(),
        ),
        if (widget.transaction.blockchain == Blockchain.lightning &&
            widget.transaction.destination != null &&
            widget.transaction.preimage != null) ...[
          const SizedBox(height: 12),
          _buildActionButton(
            context: context,
            label: 'Validar Pagamento',
            subtitle: 'Verificar preimagem',
            icon: Icons.verified,
            onPressed: () => _openValidationUrl(),
          ),
        ],
        if (isRefundable) ...[
          const SizedBox(height: 12),
          _buildActionButton(
            context: context,
            label: 'Solicitar Reembolso',
            subtitle: 'Recuperar seus fundos',
            icon: Icons.refresh,
            onPressed: () {
              context.push('/transactions/refund', extra: widget.transaction);
            },
            isDestructive: true,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isDestructive
                  ? Colors.red.withValues(alpha: 0.15)
                  : Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDestructive
                    ? Colors.red.withValues(alpha: 0.3)
                    : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    isDestructive
                        ? Colors.red.withValues(alpha: 0.2)
                        : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color:
                    isDestructive
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
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
        return "Swap";
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
        Blockchain.bitcoin => 'https://mempool.bitaroo.net/pt/tx/$txId',
        Blockchain.liquid => 'https://liquid.network/pt/tx/$txId',
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

  Future<void> _openValidationUrl() async {
    if (widget.transaction.destination == null ||
        widget.transaction.preimage == null) {
      return;
    }

    final validationUrl =
        'https://validate-payment.com/?invoice=${widget.transaction.destination!}&preimage=${widget.transaction.preimage!}';

    final Uri url = Uri.parse(validationUrl);

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
        await Clipboard.setData(ClipboardData(text: validationUrl));
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
      _buildInfoRow(
        icon: Icons.call_made,
        label:
            'ID Envio (${_getBlockchainName(widget.transaction.sendBlockchain!)})',
        value: truncateHashId(widget.transaction.sendTxId!),
        copyable: true,
        copyFieldId: 'send_tx_id',
        copyValue: widget.transaction.sendTxId!,
      ),
      _buildInfoRow(
        icon: Icons.call_received,
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
