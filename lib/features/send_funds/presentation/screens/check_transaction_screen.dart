import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/send_founds/data/check_transaction_screen_data.dart';
import 'package:mooze_mobile/shared/widgets/buttons/slide_to_confirm_button.dart';
import 'package:mooze_mobile/shared/widgets/info_row.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class CheckTransactionScreen extends StatefulWidget {
  const CheckTransactionScreen({super.key});

  @override
  State<CheckTransactionScreen> createState() => _CheckTransactionScreenState();
}

class _CheckTransactionScreenState extends State<CheckTransactionScreen> {
  // Constants - Layout
  static const double _horizontalPadding = 24.0;
  static const double _cardPadding = 12.0;
  static const double _cardBorderRadius = 12.0;
  static const double _sectionSpacing = 16.0;

  // Dados da transação
  static const List<PaymentDetail> _paymentDetails = PaymentDetail.paymentDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar transação')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          _horizontalPadding,
          0,
          _horizontalPadding,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('Endereço'),
            _buildCardText('bc1q0jvsc3nrlm00rhtsdvfq3la6su37ugzlq66t7n'),

            SizedBox(height: _sectionSpacing),

            _buildSectionLabel('Quantidade'),
            _buildCardText('0.312 BTC'),

            SizedBox(height: _sectionSpacing),

            _buildSectionLabel('Dados adicionais'),
            _buildPaymentDetails(),

            const Spacer(),

            SlideToConfirmButton(
              text: 'Confirmar',
              onSlideComplete: () {
                print('Confirmação concluída!');
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Widget _buildCardText(String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(_cardPadding),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      child: Text(
        content,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: _cardPadding + 4,
        vertical: _cardPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      child: Column(
        children: _paymentDetails.map(
          (detail) => InfoRow(
            label: detail.label,
            value: detail.value,
            fontSize: 14,
          ),
        ).toList(),
      ),
    );
  }
}