import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/domain/entities/refund.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/refund_confirmation_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

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
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.refund_details_title),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: t.common_back,
        ),
      ),
      body: PlatformSafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                context.colors.primaryColor.withValues(
                                  alpha: 0.15,
                                ),
                                context.colors.primaryColor.withValues(
                                  alpha: 0.05,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.colors.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.colors.primaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  color: context.colors.primaryColor,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  t.refund_auto_send_info,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Swap Details Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.colors.backgroundCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.colors.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.refund_info_title,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Amount
                              _buildDetailRow(
                                icon: Icons.currency_bitcoin,
                                label: t.refund_label_amount,
                                value: _formatAmount(
                                  widget.swapInfo.amountSat.toInt(),
                                ),
                                isHighlight: true,
                              ),

                              SizedBox(height: 16),

                              // Transaction
                              _buildDetailRow(
                                icon: Icons.link,
                                label: t.refund_label_transaction,
                                value: _shortenAddress(
                                  widget.swapInfo.swapAddress,
                                ),
                                isHighlight: false,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Bitcoin Address Input
                        Text(
                          t.refund_address_label,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          style: context.textTheme.bodyMedium,
                          // readOnly: true,
                          decoration: InputDecoration(
                            hintText: t.refund_address_hint,
                            hintStyle: TextStyle(
                              color: context.colors.textSecondary,
                            ),
                            filled: true,
                            fillColor: context.colors.backgroundCard,
                            prefixIcon: Icon(
                              Icons.account_balance_wallet,
                              color: context.colors.primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.colors.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.colors.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.colors.primaryColor,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return t.refund_address_required;
                            }

                            final address = value.trim();

                            // Comprehensive Bitcoin address validation
                            final legacyPattern = RegExp(
                              r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$',
                            );
                            final segwitPattern = RegExp(
                              r'^bc1[a-z0-9]{39,59}$',
                            );
                            final testnetPattern = RegExp(
                              r'^(tb1|[mn2])[a-z0-9]{25,59}$',
                            );

                            final isValid =
                                legacyPattern.hasMatch(address) ||
                                segwitPattern.hasMatch(address) ||
                                testnetPattern.hasMatch(address);

                            if (!isValid) {
                              return t.refund_address_invalid;
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: t.common_next,
                onPressed: _prepareRefund,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isHighlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isHighlight
                ? context.colors.primaryColor.withValues(alpha: 0.1)
                : context.colors.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border:
            isHighlight
                ? Border.all(
                  color: context.colors.primaryColor.withValues(alpha: 0.3),
                )
                : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                isHighlight
                    ? context.colors.primaryColor
                    : context.colors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style:
                      isHighlight
                          ? context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )
                          : context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int satoshis) {
    const decimalPlaces = 8;
    final divisor = BigInt.from(10).pow(decimalPlaces);
    final value = satoshis / divisor.toDouble();
    return '${value.toStringAsFixed(decimalPlaces)} BTC';
  }

  String _shortenAddress(String address) {
    if (address.length <= 16) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 8)}';
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
        AppSnackBar.error(
          context,
          AppLocalizations.of(context).error_generic(error.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
