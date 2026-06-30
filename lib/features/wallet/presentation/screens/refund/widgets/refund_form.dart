import 'package:flutter/material.dart';
import 'package:mooze_mobile/domain/entities/refund.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Form widget for entering refund address and viewing swap details
class RefundForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController addressController;
  final RefundableSwap swapInfo;

  const RefundForm({
    super.key,
    required this.formKey,
    required this.addressController,
    required this.swapInfo,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bitcoin address input
          Text(
            t.refund_address_label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: addressController,
            style: TextStyle(color: context.colors.textPrimary),
            decoration: InputDecoration(
              hintText: t.refund_address_hint,
              hintStyle: TextStyle(color: context.colors.textSecondary),
              filled: true,
              fillColor: context.colors.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return t.refund_address_required;
              }

              final address = value.trim();

              // Comprehensive Bitcoin address validation
              // Legacy (P2PKH): starts with 1, 26-35 chars
              // SegWit (P2SH): starts with 3, 26-35 chars
              // Native SegWit (Bech32): starts with bc1, 42-62 chars
              // Testnet: starts with tb1, m, n, or 2

              final legacyPattern = RegExp(
                r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$',
              );
              final segwitPattern = RegExp(r'^bc1[a-z0-9]{39,59}$');
              final testnetPattern = RegExp(r'^(tb1|[mn2])[a-z0-9]{25,59}$');

              final isValid =
                  legacyPattern.hasMatch(address) ||
                  segwitPattern.hasMatch(address) ||
                  testnetPattern.hasMatch(address);

              if (!isValid) {
                return t.refund_address_invalid_long;
              }

              return null;
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(
              height: 32.0,
              color: Color.fromRGBO(40, 59, 74, 0.5),
            ),
          ),

          // Refund amount
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildDetailRow(
              t.refund_label_refund_amount,
              _formatAmount(swapInfo.amountSat.toInt()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Divider(
              height: 32.0,
              color: Color.fromRGBO(40, 59, 74, 0.5),
            ),
          ),

          // Original transaction address
          _buildDetailRow(
            t.refund_label_transaction,
            _shortenAddress(swapInfo.swapAddress),
            fullValue: swapInfo.swapAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {String? fullValue}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(
            '$label:',
            style: const TextStyle(fontSize: 18.0, color: Colors.white),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 18.0, color: Colors.white),
            textAlign: TextAlign.right,
            maxLines: fullValue != null ? 1 : null,
            overflow: fullValue != null ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
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
}
