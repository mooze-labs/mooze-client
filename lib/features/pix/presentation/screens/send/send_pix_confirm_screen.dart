import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/receive/presentation/widgets/loading_overlay_widget.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/send/providers.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/utils/formatters.dart';

String formatNumber(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
}

class SendPixConfirmScreen extends ConsumerStatefulWidget {
  const SendPixConfirmScreen({super.key});

  @override
  ConsumerState<SendPixConfirmScreen> createState() =>
      _SendPixConfirmScreenState();
}

class _SendPixConfirmScreenState extends ConsumerState<SendPixConfirmScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;
  OverlayEntry? _overlayEntry;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _circleAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _circleController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amountInCents) {
    final reais = amountInCents / 100;
    return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  void _showLoadingOverlay() {
    if (_overlayEntry != null) return;
    if (!mounted) return;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => LoadingOverlayWidget(
            circleController: _circleController,
            circleAnimation: _circleAnimation,
            loadingText: 'Processando pagamento...',
            showLoadingText: true,
          ),
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(_overlayEntry!);
  }

  void _hideLoadingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _onSlideComplete() async {
    final paymentRequest = ref.read(currentPixPaymentRequestProvider);
    if (paymentRequest == null) return;

    setState(() => _isLoading = true);
    _showLoadingOverlay();
    _circleController.forward();

    final minAnimationTime = Future.delayed(const Duration(milliseconds: 1500));

    try {
      final controller = ref.read(pixSendControllerProvider);

      // TODO: Integrar com Breez SDK para pagar o invoice
      final result =
          await controller.confirmPayment(paymentRequest.invoice).run();

      await minAnimationTime;

      result.fold(
        (error) {
          if (mounted) {
            setState(() => _isLoading = false);
            _hideLoadingOverlay();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
            _circleController.reset();
          }
        },
        (payment) {
          if (mounted) {
            setState(() => _isLoading = false);
            ref.read(currentPixPaymentProvider.notifier).state = payment;
            context.pushReplacement(
              '/pix/send/processing/${payment.withdrawId}',
            );
          }

          Future.delayed(const Duration(milliseconds: 200)).then((_) {
            if (mounted) {
              _hideLoadingOverlay();
              _circleController.reset();
            }
          });
        },
      );
    } catch (e) {
      await minAnimationTime;
      if (mounted) {
        setState(() => _isLoading = false);
        _hideLoadingOverlay();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
        _circleController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentRequest = ref.watch(currentPixPaymentRequestProvider);

    if (paymentRequest == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/pix');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Pagamento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: PlatformSafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Ícone PIX
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.3,
                            ),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.pix,
                          size: 40,
                          color: AppColors.primaryColor,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Valor principal
                      Text(
                        _formatCurrency(paymentRequest.valueInBrl),
                        style: Theme.of(
                          context,
                        ).textTheme.displaySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Pagamento PIX',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Detalhes do pagamento
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.2,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              'Chave PIX',
                              truncateHashId(paymentRequest.pixKey, length: 20),
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Valor em Satoshis',
                              '${formatNumber(paymentRequest.valueInSatoshis)} sats',
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Taxa',
                              _formatCurrency(paymentRequest.fee),
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Cotação BTC/BRL',
                              'R\$ ${formatNumber(paymentRequest.quote.btcToBrlRate.toInt())}',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Info sobre L-BTC
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.bolt,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'O pagamento será instantâneo usando Lightning Network.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Slide to confirm
              SlideToConfirmButton(
                onSlideComplete: _onSlideComplete,
                text: 'Confirmar Pagamento',
                isLoading: _isLoading,
                isEnabled: !_isLoading,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
