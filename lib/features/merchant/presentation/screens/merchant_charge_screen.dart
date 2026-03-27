import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/cart_item_entity.dart';
import 'package:mooze_mobile/features/merchant/presentation/controllers/controllers.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_onboarding_service_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/selected_asset_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/pix_deposit_controller_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/asset_selector_widget.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/loading_overlay_widget.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/transaction_details_widget.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/first_time_pix_dialog.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_limits_info_dialog.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_unavailable_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Merchant Charge Screen (Presentation Layer)
///
/// The payment/checkout screen for merchant mode transactions.
/// This screen is reached after the merchant clicks "Finalizar Venda" (Complete Sale)
/// from the merchant mode screen.
///

class MerchantChargeScreen extends ConsumerStatefulWidget {
  /// Total amount to charge (in BRL)
  final double totalAmount;

  /// List of cart items being purchased
  final List<CartItemEntity> items;

  const MerchantChargeScreen({
    super.key,
    required this.totalAmount,
    required this.items,
  });

  @override
  ConsumerState<MerchantChargeScreen> createState() =>
      _MerchantChargeScreenState();
}

class _MerchantChargeScreenState extends ConsumerState<MerchantChargeScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;
  OverlayEntry? _overlayEntry;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeAccess();
      if (mounted) {
        ref.read(depositAmountProvider.notifier).state = widget.totalAmount;
      }
    });
  }

  void _initializeControllers() {
    _circleController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _circleAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _checkFirstTimeAccess() async {
    final onboardingService = ref.read(pixOnboardingServiceProvider);

    if (!onboardingService.hasSeenMerchantFirstTimeDialog() && mounted) {
      final accepted = await FirstTimePixDialog.show(context);

      if (accepted == true && mounted) {
        await onboardingService.markMerchantFirstTimeDialogAsSeen();

        if (mounted) {
          await PixLimitsInfoDialog.show(context);
        }

        // TODO: When there is an API, uncomment to sync with the backend
        // await onboardingService.submitTermsAcceptance();
      }
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _circleController.dispose();
    super.dispose();
  }

  void _onSlideComplete() async {
    setState(() => _isLoading = true);

    _showLoadingOverlay();
    _circleController.forward();

    final controller = await ref.read(pixDepositControllerProvider.future);
    final depositAmount = ref.read(depositAmountProvider);
    final selectedAsset = ref.read(selectedAssetProvider);

    final amountInCents = (depositAmount * 100).toInt();

    final minAnimationTime = Future.delayed(Duration(milliseconds: 1500));

    controller.fold(
      (err) async {
        await minAnimationTime;
        if (mounted) {
          setState(() => _isLoading = false);
          _hideLoadingOverlay();
          _circleController.reset();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Theme.of(context).colorScheme.onError,
                onPressed: () {},
              ),
            ),
          );
        }
      },
      (controller) async {
        final result =
            await controller.newDeposit(amountInCents, selectedAsset).run();

        await minAnimationTime;

        result.fold(
          (err) {
            if (mounted) {
              setState(() => _isLoading = false);
              _hideLoadingOverlay();
              _circleController.reset();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(err),
                  backgroundColor: Colors.red[700],
                  duration: Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
            }
          },
          (deposit) async {
            if (!mounted) return;

            setState(() => _isLoading = false);

            context.push("/pix/payment/${deposit.depositId}").then((_) {
              if (mounted) {
                _circleController.reset();
                ref.read(depositAmountProvider.notifier).state =
                    widget.totalAmount;
                ref.invalidate(pixDepositControllerProvider);
                ref.invalidate(feeRateProvider);
                ref.invalidate(feeAmountProvider);
                ref.invalidate(discountedFeesDepositProvider);
                ref.invalidate(assetQuoteProvider);
              }
            });

            await Future.delayed(Duration(milliseconds: 200));
            if (mounted) {
              _hideLoadingOverlay();
            }
          },
        );
      },
    );
  }

  void _showLoadingOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => LoadingOverlayWidget(
            circleController: _circleController,
            circleAnimation: _circleAnimation,
            loadingText: 'Gerando QR Code...',
            showLoadingText: true,
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideLoadingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEA1E63), Color(0xFF841138)],
              ),
            ),
            child: PlatformSafeArea(
              iosTop: true,
              androidTop: true,
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colors.backgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                        ).copyWith(top: 20),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInstructionText(),
                              SizedBox(height: 20),
                              AssetSelectorWidget(),
                              SizedBox(height: 20),
                              _buildLimitsInfo(),
                              SizedBox(height: 20),
                              _buildItemsList(),
                              SizedBox(height: 20),
                              TransactionDisplayWidget(),
                              SizedBox(height: 20),
                              Builder(
                                builder: (context) {
                                  final validation = ref.watch(
                                    merchantValidationProvider(
                                      widget.totalAmount,
                                    ),
                                  );
                                  return Opacity(
                                    opacity: validation.isValid ? 1.0 : 0.5,
                                    child: IgnorePointer(
                                      ignoring: !validation.isValid,
                                      child: SlideToConfirmButton(
                                        onSlideComplete: _onSlideComplete,
                                        text: 'Gerar QR Code',
                                        isLoading: _isLoading,
                                        isEnabled: validation.isValid,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ApiUnavailableOverlay(
            showBackButton: true,
            onBack: () => context.pop(),
            onRetry: () {
              ref.invalidate(pixDepositControllerProvider);
              ref.invalidate(depositAmountProvider);
            },
            customMessage:
                'Não é possível processar transações PIX no momento. Por favor, tente novamente mais tarde.',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final validation = ref.watch(
      merchantValidationProvider(widget.totalAmount),
    );

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Text(
                'Receber',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 48),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'R\$${widget.totalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!validation.isValid && validation.message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                validation.message!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: context.appColors.editColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionText() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: 'Escolha o ativo que deseja receber na ',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: 'Mooze',
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitsInfo() {
    return Consumer(
      builder: (context, ref, child) {
        final levelsData = ref.watch(levelsProvider);

        return levelsData.when(
          data:
              (data) => Column(
                children: [
                  _buildLimitRow(
                    'Limite diário',
                    'R\$ ${UserLevelsData.dailyLimit.toStringAsFixed(2)}',
                  ),
                  SizedBox(height: 8),
                  _buildLimitRow(
                    'Por transação',
                    'R\$ ${data.allowedSpending.toStringAsFixed(2)}',
                  ),
                  SizedBox(height: 8),
                  _buildLimitRow(
                    'Valor mínimo',
                    'R\$ ${data.absoluteMinLimit.toStringAsFixed(2)}',
                  ),
                ],
              ),
          loading:
              () => Column(
                children: [
                  _buildLimitRow('Limite diário', 'Carregando...'),
                  SizedBox(height: 8),
                  _buildLimitRow('Por transação', 'Carregando...'),
                  SizedBox(height: 8),
                  _buildLimitRow('Valor mínimo', 'Carregando...'),
                ],
              ),
          error:
              (error, stack) => Column(
                children: [
                  _buildLimitRow(
                    'Limite diário',
                    'R\$ ${UserLevelsData.dailyLimit.toStringAsFixed(2)}',
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.appColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: context.appColors.warning.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: context.appColors.warning,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Erro ao carregar limites',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelMedium?.copyWith(
                                  color: context.appColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ref.invalidate(levelsProvider);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: context.appColors.warning,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tentar novamente',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        );
      },
    );
  }

  Widget _buildLimitRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Itens',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        ...widget.items.map((item) => _buildItemRow(item)),
      ],
    );
  }

  Widget _buildItemRow(CartItemEntity item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'R\$ ${item.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'x${item.quantity}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
