import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/send/providers.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SendPixProcessingScreen extends ConsumerStatefulWidget {
  final String withdrawId;

  const SendPixProcessingScreen({super.key, required this.withdrawId});

  @override
  ConsumerState<SendPixProcessingScreen> createState() =>
      _SendPixProcessingScreenState();
}

class _SendPixProcessingScreenState
    extends ConsumerState<SendPixProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final withdrawStatusStream = ref.watch(
      withdrawStatusProvider(widget.withdrawId),
    );

    return withdrawStatusStream.when(
      data: (result) {
        return result.fold((error) => _buildErrorScreen(error), (status) {
          if (status.status == 'completed') {
            // Navegar para tela de sucesso
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.pushReplacement(
                  '/pix/send/success/${widget.withdrawId}',
                );
              }
            });
          } else if (status.status == 'failed') {
            return _buildErrorScreen(
              status.errorMessage ?? 'Falha no processamento do pagamento',
            );
          }

          return _buildProcessingScreen();
        });
      },
      loading: () => _buildProcessingScreen(),
      error: (error, _) => _buildErrorScreen(error.toString()),
    );
  }

  Widget _buildProcessingScreen() {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: PlatformSafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.4),
                radius: 0.8,
                colors: [
                  Color(0xFF1A0A1A),
                  AppColors.backgroundColor,
                  AppColors.backgroundColor,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone animado
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.hourglass_empty,
                        size: 60,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Título
                  Text(
                    'Processando Pagamento',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Descrição
                  Text(
                    'Seu PIX está sendo processado. Isso pode levar alguns instantes...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Loading indicator
                  LoadingAnimationWidget.threeRotatingDots(
                    color: AppColors.primaryColor,
                    size: 50,
                  ),

                  const SizedBox(height: 40),

                  // Info adicional
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aguarde enquanto verificamos o status do seu pagamento.',
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
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Erro no Pagamento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/pix'),
        ),
      ),
      body: PlatformSafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Erro no Pagamento',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                error,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              PrimaryButton(
                text: 'Voltar',
                onPressed: () => context.go('/pix'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
