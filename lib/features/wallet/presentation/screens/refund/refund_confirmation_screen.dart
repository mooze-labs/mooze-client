import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/refund_success_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/widgets/fee_chooser.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

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
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Voltar',
        ),
      ),
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
            return _buildLoadingView();
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
              ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: PrimaryButton(
                    text: 'Confirmar Reembolso',
                    onPressed: _confirmRefund,
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.backgroundCard.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colors.primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: CircularProgressIndicator(
              color: context.colors.primaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Calculando taxas...',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    final colorScheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: context.colors.backgroundCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.error.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: colorScheme.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ],
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
      builder:
          (ctx) => Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.4),
                radius: 0.8,
                colors: [
                  ctx.colorScheme.primary.withValues(alpha: 0.08),
                  ctx.colors.backgroundColor,
                ],
              ),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ctx.colors.backgroundCard.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ctx.colors.primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: CircularProgressIndicator(
                  color: ctx.colors.primaryColor,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
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

        // Close confirmation screen
        Navigator.of(context).pop();

        // Show success screen
        RefundSuccessScreen.show(
          context,
          txid: response.refundTxId,
          amountSat: widget.refundParams.refundAmountSat.toDouble(),
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
            backgroundColor: context.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
