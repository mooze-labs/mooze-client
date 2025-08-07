import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/new_ui_wallet/pix/data/payment_detail_data_page.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/extensions/responsive_extensions.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/custom_app_bar.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/info_row.dart';

/*
class PixPaymentScreen extends StatefulWidget {
  const PixPaymentScreen({super.key});

  @override
  State<PixPaymentScreen> createState() => _PixPaymentScreenState();
}

class _PixPaymentScreenState extends State<PixPaymentScreen> {
  // State
  int _minutes = 4;
  int _seconds = 52;

  // Constants - Dimensions
  static const double _contentPadding = 16.0;
  static const double _qrCodeSize = 314.0;
  static const double _containerPadding = 16.0;
  static const double _containerVerticalPadding = 12.0;
  static const double _borderRadius = 8.0;
  static const double _iconSize = 20.0;
  static const double _copyIconSize = 16.0;

  // Constants - Colors
  static const Color _backgroundColor = Color(0xFF0A0A0A);
  static const Color _cardBackground = Color(0xFF2A2A2A);
  static const Color _primaryColor = Color(0xFFEA1E63);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF9194A6);
  static const Color _textTertiary = Color(0xFF8E8E8E);
  static const Color _positiveColor = Colors.green;

  // Constants - Mock Data
  static const String _pixCode = '00020101023226860014bt.gov...';
  static const String _poweredByText = 'Powered by Depix.info';

  // Constants - Payment Details
  static const List<PaymentDetail> _paymentDetails =
      PaymentDetail.paymentDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(_contentPadding),
                child: Column(
                  children: [
                    _buildTimerText(),
                    const Spacer(),
                    _buildQRCodeSection(constraints),
                    const Spacer(),
                    _buildPoweredByText(),
                    const Spacer(),
                    _buildCopyableAddress(),
                    const Spacer(),
                    _buildPaymentDetails(),
                    const Spacer(),
                    _buildVerifyButton(),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: TextSpan(
        text: 'Pagamento ',
        style: AppTextStyles.title,
        children: [
          TextSpan(
            text: 'PIX',
            style: AppTextStyles.title.copyWith(color: _primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerText() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTextStyles.subtitle,
        children: [
          const TextSpan(text: 'Você tem '),
          TextSpan(
            text: '$_minutes minutos e $_seconds segundos',
            style: const TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(text: ' para concluir o pagamento.'),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection(BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth - (_contentPadding * 2);
    final screenHeight = constraints.maxHeight;

    final reservedHeight = 400.0;
    final availableHeight = screenHeight - reservedHeight;

    final maxSize = math.min(screenWidth * 0.8, availableHeight * 0.8);

    final qrSize = math.max(180.0, math.min(maxSize, 314.0));

    return Container(
      width: qrSize,
      height: qrSize,
      child: Image.asset(
        'assets/images/qrcode.png',
        width: qrSize,
        height: qrSize,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildPoweredByText() {
    return Text(
      _poweredByText,
      style: const TextStyle(color: _textSecondary, fontSize: 12),
    );
  }

  Widget _buildCopyableAddress() {
    return GestureDetector(
      onTap: _handleCopyAddress,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _containerPadding,
          vertical: _containerVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.link_rounded,
              color: _primaryColor,
              size: _iconSize,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _pixCode,
                style: AppTextStyles.value,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.copy, color: _primaryColor, size: _copyIconSize),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _containerPadding,
        vertical: _containerVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: const [BoxShadow(color: Color(0x4DEA1E63), blurRadius: 8)],
      ),
      child: Column(
        children:
            _paymentDetails
                .map(
                  (detail) => InfoRow(
                    label: detail.label,
                    value: detail.value,
                    fontSize: context.responsiveFont(14),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return PrimaryButton(
      text: 'Verificar Pagamento',
      onPressed: _handleVerifyPayment,
    );
  }

  void _handleCopyAddress() {
    Clipboard.setData(const ClipboardData(text: _pixCode));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Endereço copiado!'),
        ),
      );
    }
  }

  void _handleVerifyPayment() {
    // TODO: Implement payment verification
  }

  void _startTimer() {
    // TODO: Implement actual countdown timer
  }

  void _handleTimerExpired() {
    // TODO: Implement action when timer expires
    // - Show expiration dialog
    // - Navigate back
    // - Renew payment
  }
}
*/