import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/refund_confirmation_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/widgets/refund_form.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

/// Screen to enter refund address and review swap details
class RefundScreen extends ConsumerStatefulWidget {
  static const String routeName = '/refund';

  final RefundableSwap swapInfo;

  const RefundScreen({super.key, required this.swapInfo});

  @override
  ConsumerState<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends ConsumerState<RefundScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Try to get a bitcoin address
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(refundProvider);
      if (state.bitcoinAddress != null) {
        _addressController.text = state.bitcoinAddress!;
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Reembolso'),
        backgroundColor: AppColors.backgroundColor,
      ),
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: ShapeDecoration(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      color: AppColors.backgroundCard,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 24,
                    ),
                    child: RefundForm(
                      formKey: _formKey,
                      addressController: _addressController,
                      swapInfo: widget.swapInfo,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _prepareRefund,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.backgroundColor,
                disabledBackgroundColor: AppColors.textSecondary.withValues(
                  alpha: 0.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Próximo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _prepareRefund() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final refundParams = RefundParams(
        refundAmountSat: widget.swapInfo.amountSat.toInt(),
        swapAddress: widget.swapInfo.swapAddress,
        toAddress: _addressController.text.trim(),
      );

      // Navigate to confirmation screen
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) => RefundConfirmationScreen(refundParams: refundParams),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
