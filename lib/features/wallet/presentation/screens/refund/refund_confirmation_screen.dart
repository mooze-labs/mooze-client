import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/widgets/fee_chooser.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

/// Screen to select fee rate and confirm refund
class RefundConfirmationScreen extends ConsumerStatefulWidget {
  static const String routeName = '/refund_confirmation';

  final RefundParams refundParams;

  const RefundConfirmationScreen({super.key, required this.refundParams});

  @override
  ConsumerState<RefundConfirmationScreen> createState() =>
      _RefundConfirmationScreenState();
}

class _RefundConfirmationScreenState
    extends ConsumerState<RefundConfirmationScreen> {
  List<RefundFeeOption> affordableFees = [];
  int selectedFeeIndex = -1;
  late Future<List<RefundFeeOption>> _fetchFeeOptionsFuture;

  @override
  void initState() {
    super.initState();
    _fetchRefundFeeOptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Velocidade da Transação'),
        backgroundColor: AppColors.backgroundColor,
      ),
      backgroundColor: AppColors.backgroundColor,
      body: FutureBuilder<List<RefundFeeOption>>(
        future: _fetchFeeOptionsFuture,
        builder: (context, snapshot) {
          if (snapshot.error != null) {
            return _buildErrorMessage(
              snapshot.error.toString().contains('InsufficientFunds')
                  ? 'Fundos insuficientes para cobrir a taxa de transação'
                  : 'Erro ao recuperar taxas: ${snapshot.error}',
            );
          }

          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (affordableFees.isNotEmpty) {
            return FeeChooser(
              amountSat: widget.refundParams.refundAmountSat,
              feeOptions: snapshot.data!,
              selectedFeeIndex: selectedFeeIndex,
              onSelect:
                  (index) => setState(() {
                    selectedFeeIndex = index;
                  }),
            );
          } else {
            return _buildErrorMessage(
              'Valor muito pequeno para cobrir as taxas de transação',
            );
          }
        },
      ),
      bottomNavigationBar:
          (affordableFees.isNotEmpty &&
                  selectedFeeIndex >= 0 &&
                  selectedFeeIndex < affordableFees.length)
              ? SafeArea(child: _buildConfirmButton())
              : null,
    );
  }

  Widget _buildErrorMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () => _confirmRefund(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: AppColors.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Confirmar Reembolso',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRefund() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final req = RefundRequest(
        feeRateSatPerVbyte:
            affordableFees[selectedFeeIndex].feeRateSatPerVbyte.toInt(),
        refundAddress: widget.refundParams.toAddress,
        swapAddress: widget.refundParams.swapAddress,
      );

      final response = await ref
          .read(refundProvider.notifier)
          .processRefund(req: req);

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                backgroundColor: AppColors.backgroundCard,
                title: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 32,
                    ),
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
                      child: SelectableText(
                        response.refundTxId,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Close dialog and pop back to home
                      Navigator.of(context).pop();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar reembolso: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _fetchRefundFeeOptions() {
    final refundNotifier = ref.read(refundProvider.notifier);
    _fetchFeeOptionsFuture = refundNotifier.fetchRefundFeeOptions(
      params: widget.refundParams,
    );

    _fetchFeeOptionsFuture.then(
      (feeOptions) {
        if (mounted) {
          setState(() {
            affordableFees =
                feeOptions
                    .where(
                      (f) => f.isAffordable(
                        feeCoverageSat: widget.refundParams.refundAmountSat,
                      ),
                    )
                    .toList();
            selectedFeeIndex = (affordableFees.length / 2).floor();
          });
        }
      },
      onError: (error, stackTrace) {
        setState(() {
          affordableFees = [];
          selectedFeeIndex = -1;
        });
      },
    );
  }
}
