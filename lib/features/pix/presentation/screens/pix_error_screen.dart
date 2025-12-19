import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/utils/formatters.dart';

class PixErrorScreen extends StatefulWidget {
  final Asset asset;
  final int amountInCents;
  final String depositId;
  final String? errorMessage;

  const PixErrorScreen({
    super.key,
    required this.asset,
    required this.amountInCents,
    required this.depositId,
    this.errorMessage,
  });

  static void show(
    BuildContext context, {
    required Asset asset,
    required int amountInCents,
    required String depositId,
    String? errorMessage,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, _) => PixErrorScreen(
              asset: asset,
              amountInCents: amountInCents,
              depositId: depositId,
              errorMessage: errorMessage,
            ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<PixErrorScreen> createState() => _PixErrorScreenState();
}

class _PixErrorScreenState extends State<PixErrorScreen>
    with TickerProviderStateMixin {
  bool _depositIdCopied = false;

  late AnimationController _iconController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  late Animation<double> _iconAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _iconAnimation = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
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
    _iconController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _pulseController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _iconController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amountInCents) {
    final reais = amountInCents / 100;
    return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: PlatformSafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.4),
              radius: 0.8,
              colors: [
                Color(0xFF1A0606),
                AppColors.backgroundColor,
                AppColors.backgroundColor,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(
                                  alpha: 0.2 + (_pulseAnimation.value * 0.3),
                                ),
                                blurRadius: 40 + (_pulseAnimation.value * 30),
                                spreadRadius: 8 + (_pulseAnimation.value * 15),
                              ),
                            ],
                          ),
                          child: ScaleTransition(
                            scale: _iconAnimation,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 25,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
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

                Expanded(
                  flex: 4,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Depósito Falhou',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          widget.errorMessage ??
                              'Ocorreu um problema durante o processamento do seu depósito PIX.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.pix,
                                              color: AppColors.primaryColor,
                                              size: 30,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'PIX',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          _formatCurrency(widget.amountInCents),
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),
                              _buildCopyableField(
                                label: 'ID do Depósito',
                                value: truncateHashId(
                                  widget.depositId,
                                  length: 10,
                                ),
                                fullValue: widget.depositId,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Column(
                  children: [
                    PrimaryButton(
                      text: 'Voltar',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCopyableField({
    required String label,
    required String value,
    required String fullValue,
  }) {
    final isCopied = _depositIdCopied && fullValue == widget.depositId;

    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: fullValue));
        setState(() {
          _depositIdCopied = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _depositIdCopied = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isCopied
                  ? AppColors.primaryColor.withValues(alpha: 0.08)
                  : AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isCopied
                    ? AppColors.primaryColor.withValues(alpha: 0.5)
                    : AppColors.primaryColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color:
                        isCopied
                            ? AppColors.primaryColor
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Icon(
              isCopied ? Icons.check_rounded : Icons.copy_rounded,
              color:
                  isCopied
                      ? AppColors.primaryColor
                      : AppColors.primaryColor.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
