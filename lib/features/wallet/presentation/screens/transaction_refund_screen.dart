import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class TransactionRefundScreen extends ConsumerStatefulWidget {
  final Transaction transaction;

  const TransactionRefundScreen({super.key, required this.transaction});

  @override
  ConsumerState<TransactionRefundScreen> createState() =>
      _TransactionRefundScreenState();
}

class _TransactionRefundScreenState
    extends ConsumerState<TransactionRefundScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _addressController = TextEditingController();
  bool _txidCopied = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    // Load refund data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refundProvider.notifier).loadRefundData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(refundProvider);

    // Update address controller when state changes
    if (state.bitcoinAddress != null && _addressController.text.isEmpty) {
      _addressController.text = state.bitcoinAddress!;
    }

    // Show success dialog if refund completed
    if (state.refundTxId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessDialog(state.refundTxId!);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reembolso de Transação'),
        backgroundColor: AppColors.backgroundColor,
      ),
      backgroundColor: AppColors.backgroundColor,
      body:
          state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
              ? _buildErrorView(state.error!)
              : _buildRefundForm(state),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar dados',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(refundProvider.notifier).loadRefundData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.backgroundColor,
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundForm(RefundState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              Text(
                'Transação Falhada',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sua transação de peg-in não pode ser concluída. Clicando em OK, os seus bitcoins serão restituídos para sua carteira onchain.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Transaction Details Card
              _buildTransactionDetailsCard(),
              const SizedBox(height: 24),

              // Bitcoin Address Input
              _buildAddressInput(state),
              const SizedBox(height: 24),

              // Fee Selection
              if (state.recommendedFees != null) _buildFeeSelection(state),
              const SizedBox(height: 32),

              // Refund Button
              _buildRefundButton(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionDetailsCard() {
    return Card(
      color: AppColors.backgroundCard,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes da Transação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Valor', _formatAmount()),
            const SizedBox(height: 8),
            _buildDetailRow('Status', 'Falhada', valueColor: Colors.red),
            const SizedBox(height: 8),
            _buildDetailRow('Data', _formatDate()),
            const SizedBox(height: 8),
            _buildTxIdRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildTxIdRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TX ID',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _shortenTxId(
                    widget.transaction.sendTxId ??
                        widget.transaction.receiveTxId ??
                        '',
                  ),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          widget.transaction.sendTxId ??
                          widget.transaction.receiveTxId ??
                          '',
                    ),
                  );
                  setState(() => _txidCopied = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _txidCopied = false);
                  });
                },
                child: Icon(
                  _txidCopied ? Icons.check : Icons.copy,
                  size: 16,
                  color: _txidCopied ? Colors.green : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressInput(RefundState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Endereço Bitcoin para Reembolso',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Insira o endereço Bitcoin',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.backgroundCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            suffixIcon:
                state.bitcoinAddress != null
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
          ),
          maxLines: 2,
          onChanged: (value) {
            ref.read(refundProvider.notifier).setBitcoinAddress(value);
          },
        ),
        if (state.bitcoinAddress != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Endereço gerado automaticamente da sua carteira',
              style: TextStyle(fontSize: 12, color: Colors.green[400]),
            ),
          ),
      ],
    );
  }

  Widget _buildFeeSelection(RefundState state) {
    final fees = state.recommendedFees!;
    final isUsingFallback =
        state.lastFeeUpdate == null ||
        (fees.economyFee == BigInt.from(2) &&
            fees.hourFee == BigInt.from(5) &&
            fees.halfHourFee == BigInt.from(10) &&
            fees.fastestFee == BigInt.from(20));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Velocidade da Transação',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (isUsingFallback) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Usando taxas estimadas (API temporariamente indisponível)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildFeeOption(
          'Economia',
          fees.economyFee,
          '~24 horas',
          state.selectedFeeRate,
        ),
        const SizedBox(height: 8),
        _buildFeeOption(
          'Padrão',
          fees.hourFee,
          '~1 hora',
          state.selectedFeeRate,
        ),
        const SizedBox(height: 8),
        _buildFeeOption(
          'Rápido',
          fees.halfHourFee,
          '~30 minutos',
          state.selectedFeeRate,
        ),
        const SizedBox(height: 8),
        _buildFeeOption(
          'Urgente',
          fees.fastestFee,
          '~10 minutos',
          state.selectedFeeRate,
        ),
      ],
    );
  }

  Widget _buildFeeOption(
    String label,
    BigInt feeRate,
    String estimatedTime,
    BigInt? selectedFeeRate,
  ) {
    final isSelected = selectedFeeRate == feeRate;

    return InkWell(
      onTap: () {
        ref.read(refundProvider.notifier).setSelectedFeeRate(feeRate);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryColor.withValues(alpha: 0.1)
                  : AppColors.backgroundCard,
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  estimatedTime,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Text(
              '${feeRate.toString()} sat/vB',
              style: TextStyle(
                color:
                    isSelected ? AppColors.primaryColor : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundButton(RefundState state) {
    final canProcess =
        state.bitcoinAddress != null &&
        state.bitcoinAddress!.isNotEmpty &&
        state.selectedFeeRate != null &&
        state.refundableSwaps != null &&
        state.refundableSwaps!.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed:
            canProcess && !state.isLoading
                ? () async {
                  // This screen is deprecated. Use GetRefundScreen instead.
                  // For backward compatibility, we'll show an error message.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Esta tela está obsoleta. Por favor, use o novo fluxo de estorno.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.backgroundColor,
          disabledBackgroundColor: AppColors.textSecondary.withValues(
            alpha: 0.3,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            state.isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Text(
                  'Confirmar Reembolso',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  void _showSuccessDialog(String txId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Reembolso Iniciado',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu reembolso foi processado com sucesso!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  'TX ID:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _shortenTxId(txId),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: txId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('TX ID copiado!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: AppColors.primaryColor),
                ),
              ),
            ],
          ),
    );
  }

  String _formatAmount() {
    const decimalPlaces = 8;
    final divisor = BigInt.from(10).pow(decimalPlaces);
    final value = widget.transaction.amount.toDouble() / divisor.toDouble();
    return '${value.toStringAsFixed(decimalPlaces)} ${widget.transaction.asset.ticker}';
  }

  String _formatDate() {
    final date = widget.transaction.createdAt;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _shortenTxId(String txId) {
    if (txId.length <= 16) return txId;
    return '${txId.substring(0, 8)}...${txId.substring(txId.length - 8)}';
  }
}
