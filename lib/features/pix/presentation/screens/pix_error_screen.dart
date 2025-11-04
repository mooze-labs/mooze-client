import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

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
      body: SafeArea(
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
                const SizedBox(height: 40),

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
                        const Text(
                          'Depósito Falhou',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.errorMessage ??
                              'Ocorreu um problema durante o processamento do seu depósito PIX.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Asset Info Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Valor',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(widget.amountInCents),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(
                                color: Color(0xFF2A2A2A),
                                height: 1,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ativo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        widget.asset.iconPath,
                                        width: 24,
                                        height: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.asset.ticker.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Deposit ID Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2A2A2A),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ID do Depósito',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.depositId,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: widget.depositId),
                                      );
                                      setState(() {
                                        _depositIdCopied = true;
                                      });
                                      Future.delayed(
                                        const Duration(seconds: 2),
                                        () {
                                          if (mounted) {
                                            setState(() {
                                              _depositIdCopied = false;
                                            });
                                          }
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            _depositIdCopied
                                                ? AppColors.primaryColor
                                                    .withValues(alpha: 0.2)
                                                : const Color(0xFF2A2A2A),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _depositIdCopied
                                            ? Icons.check
                                            : Icons.copy,
                                        size: 16,
                                        color:
                                            _depositIdCopied
                                                ? AppColors.primaryColor
                                                : Colors.white.withValues(
                                                  alpha: 0.6,
                                                ),
                                      ),
                                    ),
                                  ),
                                ],
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Tentar Novamente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Color(0xFF2A2A2A),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Voltar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
}
