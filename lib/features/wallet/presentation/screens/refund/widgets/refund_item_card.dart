import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

/// Card widget to display a refundable swap item
class RefundItemCard extends StatelessWidget {
  final RefundableSwap refundableSwap;
  final VoidCallback onTap;

  const RefundItemCard({
    super.key,
    required this.refundableSwap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastRefundTxId = refundableSwap.lastRefundTxId ?? '';

    return Card(
      margin: const EdgeInsets.all(16),
      color: AppColors.backgroundCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction address
              _buildDetailRow(
                context,
                'Transação',
                lastRefundTxId.isNotEmpty
                    ? _shortenAddress(lastRefundTxId)
                    : _shortenAddress(refundableSwap.swapAddress),
                canCopy: true,
                fullValue:
                    lastRefundTxId.isNotEmpty
                        ? lastRefundTxId
                        : refundableSwap.swapAddress,
              ),
              const Divider(
                height: 32.0,
                color: Color.fromRGBO(40, 59, 74, 0.5),
              ),

              // Amount
              _buildDetailRow(
                context,
                'Valor',
                _formatAmount(refundableSwap.amountSat.toInt()),
              ),
              const Divider(
                height: 32.0,
                color: Color.fromRGBO(40, 59, 74, 0.5),
              ),

              // Date
              _buildDetailRow(
                context,
                'Data',
                _formatDate(refundableSwap.timestamp),
              ),
              const Divider(
                height: 32.0,
                color: Color.fromRGBO(40, 59, 74, 0.5),
              ),

              // Action button
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      backgroundColor: AppColors.primaryColor,
                      elevation: 0.0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                    ),
                    onPressed: onTap,
                    child: Text(
                      lastRefundTxId.isNotEmpty ? 'RETRANSMITIR' : 'CONTINUAR',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool canCopy = false,
    String? fullValue,
  }) {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 18.0, color: Colors.white),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canCopy && fullValue != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: fullValue));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copiado!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.copy,
                    size: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
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

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _shortenAddress(String address) {
    if (address.length <= 16) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 8)}';
  }
}
