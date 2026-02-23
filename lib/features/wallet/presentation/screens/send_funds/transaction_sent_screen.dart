import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/utils/formatters.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';

import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/address_controller_provider.dart';
import '../../providers/send_funds/amount_provider.dart';
import '../../providers/send_funds/amount_controller_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';
import '../../providers/send_funds/selected_asset_provider.dart';

class TransactionSentScreen extends ConsumerStatefulWidget {
  final Asset asset;
  final BigInt amount;
  final String destinationAddress;

  const TransactionSentScreen({
    super.key,
    required this.asset,
    required this.amount,
    required this.destinationAddress,
  });

  static void show(
    BuildContext context, {
    required Asset asset,
    required BigInt amount,
    required String destinationAddress,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, _) => TransactionSentScreen(
              asset: asset,
              amount: amount,
              destinationAddress: destinationAddress,
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
  ConsumerState<TransactionSentScreen> createState() =>
      _TransactionSentScreenState();
}

class _TransactionSentScreenState extends ConsumerState<TransactionSentScreen>
    with TickerProviderStateMixin {
  bool _addressCopied = false;
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
    _refreshBalances();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _checkController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _glowController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
  }

  /// Updates balances after successful send
  void _refreshBalances() {
    // Wait a bit to give time for the transaction to propagate
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ref.read(walletDataManagerProvider.notifier).refreshWalletData();
      }
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _glowController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _formatAmount() {
    const decimalPlaces = 8;
    final divisor = BigInt.from(10).pow(decimalPlaces);
    final value = widget.amount.toDouble() / divisor.toDouble();

    // For BTC/LBTC show in sats if value is small
    if ((widget.asset == Asset.btc || widget.asset == Asset.lbtc) &&
        widget.amount < BigInt.from(100000000)) {
      return '${widget.amount} sats';
    }

    return '${value.toStringAsFixed(decimalPlaces)} ${widget.asset.ticker}';
  }

  void _handleClose() {
    // Clear the TextEditingControllers
    ref.read(addressControllerProvider).clear();
    ref.read(amountControllerProvider).clear();

    // Clear the StateProviders
    ref.read(addressStateProvider.notifier).state = '';
    ref.read(amountStateProvider.notifier).state = 0;
    ref.read(formattedAmountProvider.notifier).state = '0';
    ref.read(selectedAssetProvider.notifier).state = Asset.lbtc;

    // Clear validation
    ref.read(sendValidationControllerProvider.notifier).clearValidation();

    // Navigate to home
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleClose();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: PlatformSafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.4),
                radius: 0.8,
                colors: [
                  Color(0xFF0A1A0A),
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
                            Text(
                              'Transação Enviada!',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Seu ${widget.asset.ticker} foi enviado com sucesso',
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        color: AppColors.primaryColor,
                                        size: 30,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Enviado',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _formatAmount(),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildCopyableField(
                                    label: 'Endereço de destino',
                                    value: truncateHashId(
                                      widget.destinationAddress,
                                      length: 10,
                                    ),
                                    fullValue: widget.destinationAddress,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Você pode acompanhar o status na seção de histórico.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const Spacer(),
                            PrimaryButton(
                              text: 'Voltar para Dashboard',
                              onPressed: _handleClose,
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

  Widget _buildCopyableField({
    required String label,
    required String value,
    required String fullValue,
  }) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: fullValue));
        setState(() {
          _addressCopied = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _addressCopied = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              _addressCopied
                  ? AppColors.primaryColor.withValues(alpha: 0.08)
                  : AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                _addressCopied
                    ? AppColors.primaryColor.withValues(alpha: 0.5)
                    : AppColors.primaryColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
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
                          _addressCopied
                              ? AppColors.primaryColor
                              : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              _addressCopied ? Icons.check_rounded : Icons.copy_rounded,
              color:
                  _addressCopied
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
