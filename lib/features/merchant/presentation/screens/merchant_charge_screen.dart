import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/merchant/presentation/providers/cart_provider.dart';
import 'package:mooze_mobile/features/merchant/presentation/providers/merchant_validation_provider.dart';
import 'package:mooze_mobile/features/pix/di/providers/pix_onboarding_service_provider.dart';
import 'package:mooze_mobile/features/pix/presentation/providers.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/receive/providers.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/receive/widgets.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/first_time_pix_dialog.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/pix_limits_info_dialog.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_unavailable_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';

class MerchantChargeScreen extends ConsumerStatefulWidget {
  final double totalAmount;
  final List<CartItem> items;

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
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 48),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'R\$${widget.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              color: validation.isValid ? Colors.white : Colors.amber,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!validation.isValid && validation.message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                validation.message!,
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
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
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
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
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
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
                              color: Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Erro ao carregar limites',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 13,
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
                                  color: Colors.orange,
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
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
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
                          style: TextStyle(color: Colors.white70, fontSize: 12),
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
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
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
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        ...widget.items.map((item) => _buildItemRow(item)),
      ],
    );
  }

  Widget _buildItemRow(CartItem item) {
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
                  item.nome,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'R\$ ${item.preco.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            'x${item.quantidade}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
