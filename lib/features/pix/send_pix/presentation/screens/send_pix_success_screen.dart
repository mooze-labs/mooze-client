import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/send_pix/presentation/providers/providers.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class SendPixSuccessScreen extends ConsumerStatefulWidget {
  final String withdrawId;

  const SendPixSuccessScreen({super.key, required this.withdrawId});

  @override
  ConsumerState<SendPixSuccessScreen> createState() =>
      _SendPixSuccessScreenState();
}

class _SendPixSuccessScreenState extends ConsumerState<SendPixSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _glowController;
  late AnimationController _fadeController;

  late Animation<double> _checkAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _checkAnimation = Tween<double>(begin: 1.8, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _checkController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _glowController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _glowController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amountInCents) {
    final reais = amountInCents / 100;
    return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final payment = ref.watch(currentPixPaymentProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.colors.backgroundColor,
        body: PlatformSafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.4),
                radius: 0.8,
                colors: [
                  Color(0xFF1A0A1A),
                  context.colors.backgroundColor,
                  context.colors.backgroundColor,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Ícone animado de sucesso
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: context.colors.primaryColor.withValues(
                                    alpha: 0.18 + (_glowAnimation.value * 0.18),
                                  ),
                                  blurRadius: 24 + (_glowAnimation.value * 20),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: context.colors.primaryColor.withValues(
                                    alpha: 0.08 + (_glowAnimation.value * 0.08),
                                  ),
                                  blurRadius: 56 + (_glowAnimation.value * 24),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ScaleTransition(
                              scale: _checkAnimation,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: context.colors.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.colors.primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 25,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Conteúdo
                  Expanded(
                    flex: 4,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_fadeAnimation),
                        child: Column(
                          children: [
                            // Título
                            Text(
                              'PIX Enviado!',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineMedium?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 16),

                            // Descrição
                            Text(
                              'Seu pagamento PIX foi realizado com sucesso!',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: context.colors.textSecondary),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 32),

                            // Card de detalhes
                            if (payment != null)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: context.colors.backgroundCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: context.colors.primaryColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: context.colors.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.pix,
                                            color: context.colors.primaryColor,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Valor enviado',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color:
                                                          context.colors
                                                              .textSecondary,
                                                    ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                _formatCurrency(
                                                  payment.valueInBrl,
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      color:
                                                          context.colors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: context.colors.primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: context.colors.primaryColor
                                              .withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: context.colors.primaryColor,
                                            size: 20,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'O destinatário já pode verificar o recebimento do PIX.',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color: context.colors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const Spacer(),

                            // Botão de ação
                            PrimaryButton(
                              text: 'Concluir',
                              onPressed: () {
                                ref
                                    .read(currentPixPaymentProvider.notifier)
                                    .state = null;
                                ref
                                    .read(
                                      currentPixPaymentRequestProvider.notifier,
                                    )
                                    .state = null;
                                context.go('/pix');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
