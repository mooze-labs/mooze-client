import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:flutter/services.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/utils/formatters.dart';

class SwapSuccessScreen extends StatefulWidget {
  final core.Asset fromAsset;
  final core.Asset toAsset;
  final double amountSent;
  final double amountReceived;
  final String txid;

  const SwapSuccessScreen({
    super.key,
    required this.fromAsset,
    required this.toAsset,
    required this.amountSent,
    required this.amountReceived,
    required this.txid,
  });

  static void show(
    BuildContext context, {
    required core.Asset fromAsset,
    required core.Asset toAsset,
    required double amountSent,
    required double amountReceived,
    required String txid,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, _) => SwapSuccessScreen(
              fromAsset: fromAsset,
              toAsset: toAsset,
              amountSent: amountSent,
              amountReceived: amountReceived,
              txid: txid,
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
  State<SwapSuccessScreen> createState() => _SwapSuccessScreenState();
}

class _SwapSuccessScreenState extends State<SwapSuccessScreen>
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
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Scaffold(
      body: SafeArea(
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
                                    alpha: 1,
                                  ),
                                  blurRadius: 80,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check,
                              color: colorScheme.onPrimary,
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
                          'Swap Realizado!',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Sua transação foi processada com sucesso, em instantes o saldo estará disponível na sua carteira.',
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Swap Info
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
                              // FROM -> TO
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              widget.fromAsset.iconPath,
                                              width: 20,
                                              height: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              widget.fromAsset.name,
                                              style: textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.amountSent.toStringAsFixed(8),
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
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
                                      color: context.colors.primaryColor,
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
                                              widget.toAsset.iconPath,
                                              width: 20,
                                              height: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              widget.toAsset.name,
                                              style: textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.amountReceived.toStringAsFixed(
                                            8,
                                          ),
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        _txidCopied
                                            ? context.colors.primaryColor
                                                .withValues(alpha: 0.08)
                                            : context.colors.backgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          _txidCopied
                                              ? context.colors.primaryColor
                                                  .withValues(alpha: 0.5)
                                              : context.colors.primaryColor
                                                  .withValues(alpha: 0.2),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ID da Transação',
                                            style: textTheme.bodySmall,
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            truncateHashId(
                                              widget.txid,
                                              length: 10,
                                            ),
                                            style: textTheme.labelLarge
                                                ?.copyWith(
                                                  color:
                                                      _txidCopied
                                                          ? colorScheme.primary
                                                          : null,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        _txidCopied
                                            ? Icons.check_rounded
                                            : Icons.copy_rounded,
                                        color:
                                            _txidCopied
                                                ? context.colors.primaryColor
                                                : context.colors.primaryColor
                                                    .withValues(alpha: 0.7),
                                        size: 20,
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
                            Navigator.of(context).pop();
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
    );
  }
}
