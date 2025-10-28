import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/user_id_provider.dart';
import '../widgets/support_error_widget.dart';
import '../widgets/user_id_container_widget.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;
  bool _isRetrying = false;
  String? _lastUserId;
  bool _hasError = false;
  String? _lastErrorTitle;
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _launchTelegramSupport(
    BuildContext context,
    ColorScheme colorScheme,
  ) async {
    final Uri url = Uri.parse("https://t.me/Moozep2pbot");
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showErrorSnackBar(context, colorScheme);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, colorScheme);
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, ColorScheme colorScheme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text("Não foi possível abrir o Telegram")),
          ],
        ),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Suporte'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.primary.withValues(alpha: 0.1),
                                  colorScheme.secondary.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: Icon(
                                    Icons.support_agent_rounded,
                                    size: 32,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Como podemos ajudar?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Para um atendimento mais eficiente, compartilhe o código abaixo com nosso suporte.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          Text(
                            'Seu código de identificação',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Consumer(
                            builder: (context, ref, child) {
                              final userIdAsync = ref.watch(
                                userIdControllerProvider,
                              );

                              return userIdAsync.when(
                                loading: () {
                                  if (_isRetrying &&
                                      _hasError &&
                                      _lastErrorTitle != null) {
                                    return SupportErrorWidget(
                                      title: _lastErrorTitle!,
                                      message: _lastErrorMessage ?? '',
                                      colorScheme: colorScheme,
                                      isLoading: true,
                                      onRetry: () {},
                                    );
                                  }
                                  return Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: colorScheme.outline.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                error: (error, stack) {
                                  const errorTitle =
                                      'Não foi possível carregar seu código';
                                  const errorMessage =
                                      'Ocorreu um erro ao carregar suas informações';

                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      setState(() {
                                        _hasError = true;
                                        _lastErrorTitle = errorTitle;
                                        _lastErrorMessage = errorMessage;
                                      });
                                    }
                                  });

                                  return SupportErrorWidget(
                                    title: errorTitle,
                                    message: errorMessage,
                                    colorScheme: colorScheme,
                                    isLoading: _isRetrying,
                                    onRetry: () async {
                                      setState(() => _isRetrying = true);
                                      await Future.delayed(
                                        const Duration(milliseconds: 500),
                                      );
                                      await ref
                                          .read(
                                            userIdControllerProvider.notifier,
                                          )
                                          .refresh();
                                      if (mounted) {
                                        setState(() {
                                          _isRetrying = false;
                                        });
                                      }
                                    },
                                  );
                                },
                                data: (userId) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted && _hasError) {
                                      setState(() {
                                        _hasError = false;
                                        _lastErrorTitle = null;
                                        _lastErrorMessage = null;
                                      });
                                    }
                                  });

                                  if (userId == null) {
                                    const errorTitle =
                                        'Não foi possível carregar seu código';
                                    const errorMessage =
                                        'Não encontramos suas informações';

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (mounted) {
                                            setState(() {
                                              _hasError = true;
                                              _lastErrorTitle = errorTitle;
                                              _lastErrorMessage = errorMessage;
                                            });
                                          }
                                        });

                                    return SupportErrorWidget(
                                      title: errorTitle,
                                      message: errorMessage,
                                      colorScheme: colorScheme,
                                      isLoading: _isRetrying,
                                      onRetry: () async {
                                        setState(() => _isRetrying = true);
                                        await Future.delayed(
                                          const Duration(milliseconds: 500),
                                        );
                                        await ref
                                            .read(
                                              userIdControllerProvider.notifier,
                                            )
                                            .refresh();
                                        if (mounted) {
                                          setState(() {
                                            _isRetrying = false;
                                          });
                                        }
                                      },
                                    );
                                  }

                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted && _lastUserId != userId) {
                                      setState(() => _lastUserId = userId);
                                    }
                                  });

                                  return UserIdContainerWidget(
                                    userId: userId,
                                    hasError: false,
                                    colorScheme: colorScheme,
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            text: 'Falar com o suporte',
                            onPressed:
                                () => _launchTelegramSupport(
                                  context,
                                  colorScheme,
                                ),
                          ),
                          const SizedBox(height: 24),
                        ],
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
