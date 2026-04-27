import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mooze_mobile/features/pix/send_pix/presentation/providers/providers.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class SendPixInputScreen extends ConsumerStatefulWidget {
  const SendPixInputScreen({super.key});

  @override
  ConsumerState<SendPixInputScreen> createState() => _SendPixInputScreenState();
}

class _SendPixInputScreenState extends ConsumerState<SendPixInputScreen> {
  final TextEditingController _pixKeyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pixKeyController.dispose();
    super.dispose();
  }

  void _showQRScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQRScanner(),
    );
  }

  Widget _buildQRScanner() {
    final t = AppLocalizations.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: context.colors.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(t.send_pix_qr_title),
          ),
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _pixKeyController.text = barcode.rawValue!;
                    Navigator.pop(context);
                    _processPixKey();
                    break;
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPixKey() async {
    final pixKey = _pixKeyController.text.trim();
    if (pixKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).send_pix_empty_key_error),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Criar pagamento PIX
      final result = await ref.read(createPixPaymentProvider(pixKey).future);

      result.fold(
        (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
          }
        },
        (paymentRequest) {
          if (mounted) {
            ref.read(currentPixPaymentRequestProvider.notifier).state =
                paymentRequest;
            context.push('/pix/send/confirm');
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.send_pix_appbar),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: PlatformSafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // Hero card com ícone
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.colors.primaryColor.withValues(alpha: 0.1),
                        context.colors.primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.colors.primaryColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colors.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.pix,
                          size: 40,
                          color: context.colors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.send_pix_insert_key,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        t.send_pix_paste_or_scan,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Campo de chave PIX
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          t.send_pix_key_label,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pixKeyController,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: t.send_pix_key_hint,
                        hintStyle: TextStyle(
                          color: context.colors.textSecondary.withValues(alpha: 0.5),
                        ),
                        suffixIcon: IconButton(
                          onPressed: _isLoading ? null : _showQRScanner,
                          icon: Icon(
                            Icons.qr_code_scanner,
                            color: context.colors.primaryColor,
                          ),
                          tooltip: t.wallet_send_address_scan_qr,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: context.colors.primaryColor.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: context.colors.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: context.colors.backgroundCard,
                        contentPadding: EdgeInsets.all(20),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Tipos de chaves aceitas
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.colors.primaryColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: context.colors.primaryColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            t.send_pix_accepted_types,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildKeyTypeRow(context, Icons.email, t.send_pix_type_email),
                      const SizedBox(height: 8),
                      _buildKeyTypeRow(context, Icons.phone, t.send_pix_type_phone),
                      const SizedBox(height: 8),
                      _buildKeyTypeRow(context, Icons.badge, t.send_pix_type_cpf_cnpj),
                      const SizedBox(height: 8),
                      _buildKeyTypeRow(context, Icons.key, t.send_pix_type_random),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Botão de continuar
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow:
                        _pixKeyController.text.isNotEmpty && !_isLoading
                            ? [
                              BoxShadow(
                                color: context.colors.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ]
                            : null,
                  ),
                  child: PrimaryButton(
                    text: _isLoading ? t.common_processing : t.common_continue,
                    onPressed: _isLoading ? null : _processPixKey,
                    isEnabled: !_isLoading && _pixKeyController.text.isNotEmpty,
                  ),
                ),

                const SizedBox(height: 16),

                // Informação
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, color: context.colors.primaryColor, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.send_pix_lightning_info,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyTypeRow(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.colors.textSecondary),
        SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
        ),
      ],
    );
  }
}
