import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class RefundSuccessScreen extends StatefulWidget {
  final String txid;
  final double amountSat;

  const RefundSuccessScreen({
    super.key,
    required this.txid,
    required this.amountSat,
  });

  static void show(
    BuildContext context, {
    required String txid,
    required double amountSat,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, _) =>
                RefundSuccessScreen(txid: txid, amountSat: amountSat),
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
  State<RefundSuccessScreen> createState() => _RefundSuccessScreenState();
}

class _RefundSuccessScreenState extends State<RefundSuccessScreen>
    with TickerProviderStateMixin {
  bool _txidCopied = false;
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
                Color(0xFF1A0A1A),
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
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.3 + (_glowAnimation.value * 0.4),
                                ),
                                blurRadius: 40 + (_glowAnimation.value * 30),
                                spreadRadius: 8 + (_glowAnimation.value * 15),
                              ),
                            ],
                          ),
                          child: ScaleTransition(
                            scale: _checkAnimation,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 25,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
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
                          // Title
                          Text(
                            'Reembolso Iniciado!',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Seu reembolso foi processado com sucesso. Em breve os fundos estarão disponíveis no endereço informado.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 32),

                          // Refund Info
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
                                // Amount
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        AppColors.primaryColor.withValues(
                                          alpha: 0.05,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primaryColor.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryColor
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.currency_bitcoin,
                                          color: AppColors.primaryColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Valor Reembolsado',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatAmount(
                                                widget.amountSat.toInt(),
                                              ),
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // TXID
                                GestureDetector(
                                  onTap: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: widget.txid),
                                    );
                                    setState(() {
                                      _txidCopied = true;
                                    });
                                    await Future.delayed(
                                      const Duration(seconds: 2),
                                    );
                                    if (mounted) {
                                      setState(() {
                                        _txidCopied = false;
                                      });
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          _txidCopied
                                              ? AppColors.primaryColor
                                                  .withValues(alpha: 0.1)
                                              : AppColors.backgroundColor
                                                  .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            _txidCopied
                                                ? AppColors.primaryColor
                                                : AppColors.primaryColor
                                                    .withValues(alpha: 0.3),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _txidCopied
                                              ? Icons.check_circle
                                              : Icons.tag,
                                          size: 18,
                                          color:
                                              _txidCopied
                                                  ? AppColors.primaryColor
                                                  : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Transaction ID',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      _txidCopied
                                                          ? AppColors
                                                              .primaryColor
                                                          : AppColors
                                                              .textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                widget.txid,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      _txidCopied
                                                          ? AppColors
                                                              .primaryColor
                                                          : AppColors
                                                              .textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'monospace',
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          _txidCopied
                                              ? Icons.check
                                              : Icons.content_copy,
                                          size: 16,
                                          color:
                                              _txidCopied
                                                  ? AppColors.primaryColor
                                                  : AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          PrimaryButton(
                            text: 'Voltar para Dashboard',
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
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
    );
  }

  String _formatAmount(int satoshis) {
    const decimalPlaces = 8;
    final divisor = BigInt.from(10).pow(decimalPlaces);
    final value = satoshis / divisor.toDouble();
    return '${value.toStringAsFixed(decimalPlaces)} BTC';
  }
}
