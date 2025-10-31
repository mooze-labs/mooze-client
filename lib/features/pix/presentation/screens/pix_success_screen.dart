import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/utils/formatters.dart';

class PixSuccessScreen extends StatefulWidget {
  final Asset asset;
  final int amountInCents;
  final double assetAmount;
  final String depositId;
  final String? blockchainTxid;

  const PixSuccessScreen({
    super.key,
    required this.asset,
    required this.amountInCents,
    required this.assetAmount,
    required this.depositId,
    this.blockchainTxid,
  });

  static void show(
    BuildContext context, {
    required Asset asset,
    required int amountInCents,
    required double assetAmount,
    required String depositId,
    String? blockchainTxid,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, _) => PixSuccessScreen(
              asset: asset,
              amountInCents: amountInCents,
              assetAmount: assetAmount,
              depositId: depositId,
              blockchainTxid: blockchainTxid,
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
  State<PixSuccessScreen> createState() => _PixSuccessScreenState();
}

class _PixSuccessScreenState extends State<PixSuccessScreen>
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
                const SizedBox(height: 40),

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
                          Text(
                            'PIX Recebido!',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Seu depósito está sendo processado',
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
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'PIX',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatCurrency(
                                              widget.amountInCents,
                                            ),
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.primaryColor,
                                        size: 20,
                                      ),
                                    ),

                                    Expanded(
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SvgPicture.asset(
                                                widget.asset.iconPath,
                                                width: 20,
                                                height: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                widget.asset.name,
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.assetAmount.toStringAsFixed(
                                              8,
                                            ),
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
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
                                  value: widget.depositId,
                                  fullValue: widget.depositId,
                                ),

                                if (widget.blockchainTxid != null) ...[
                                  const SizedBox(height: 12),
                                  _buildCopyableField(
                                    label: 'ID da Transação',
                                    value: truncateHashId(
                                      widget.blockchainTxid!,
                                      length: 10,
                                    ),
                                    fullValue: widget.blockchainTxid!,
                                  ),
                                ],
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

  Widget _buildCopyableField({
    required String label,
    required String value,
    required String fullValue,
  }) {
    final isCopied =
        _txidCopied && fullValue == widget.depositId ||
        _txidCopied && fullValue == widget.blockchainTxid;

    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: fullValue));
        setState(() {
          _txidCopied = true;
        });
        await Future.delayed(const Duration(seconds: 2));
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
