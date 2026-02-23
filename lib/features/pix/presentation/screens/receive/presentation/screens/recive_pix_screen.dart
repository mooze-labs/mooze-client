import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/di/providers/pix_onboarding_service_provider.dart';
import 'package:mooze_mobile/features/pix/presentation/providers.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/first_time_pix_dialog.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/pix_limits_info_dialog.dart';
import 'package:mooze_mobile/features/wallet/routes.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_unavailable_overlay.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import '../../providers.dart';
import '../../widgets.dart';

class ReceivePixScreen extends ConsumerStatefulWidget {
  const ReceivePixScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ReceivePixScreenState();
}

class _ReceivePixScreenState extends ConsumerState<ReceivePixScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;
  OverlayEntry? _overlayEntry;
  bool _isLoading = false;
  bool _hasShownFirstTimeDialog = false;

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _circleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(depositAmountProvider.notifier).state = 0.0;
        ref.invalidate(feeRateProvider);
        ref.invalidate(feeAmountProvider);
        ref.invalidate(discountedFeesDepositProvider);
        ref.invalidate(assetQuoteProvider);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentPage = PageVisibilityProvider.of(context);
    if (!_hasShownFirstTimeDialog && currentPage == 2) {
      _hasShownFirstTimeDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkFirstTimeAccess();
      });
    }
    if (_hasShownFirstTimeDialog && currentPage != 2) {
      _hasShownFirstTimeDialog = false;
    }
  }

  Future<void> _checkFirstTimeAccess() async {
    final onboardingService = ref.read(pixOnboardingServiceProvider);

    if (!onboardingService.hasSeenFirstTimeDialog() && mounted) {
      final accepted = await FirstTimePixDialog.show(context);

      if (accepted == true && mounted) {
        await onboardingService.markFirstTimeDialogAsSeen();

        if (mounted) {
          await PixLimitsInfoDialog.show(context);
        }

        // await onboardingService.submitTermsAcceptance();
      }
    }
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

  void _onSlideComplete(BuildContext context) async {
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
          _circleController.reset();
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(err)));
              _circleController.reset();
            }
          },
          (deposit) async {
            if (!mounted) return;

            setState(() => _isLoading = false);

            ref.read(depositAmountProvider.notifier).state = 0.0;
            ref.invalidate(feeRateProvider);
            ref.invalidate(feeAmountProvider);
            ref.invalidate(discountedFeesDepositProvider);
            ref.invalidate(assetQuoteProvider);

            context.push("/pix/payment/${deposit.depositId}").then((_) {
              if (mounted) {
                _circleController.reset();
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Receber PIX'),
        actions: [
          OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
          IconButton(
            onPressed: () => _showPixInfo(context),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(child: _buildBody(context)),
          ),
          ApiUnavailableOverlay(
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

  void _showPixInfo(BuildContext context) {
    InfoOverlay.show(
      context,
      title: 'Informações sobre PIX',
      steps: [
        InfoStep(
          icon: Icons.schedule,
          title: 'Prazo de processamento',
          description:
              'Pagamentos via PIX podem ser processados em até 72 horas úteis após a confirmação.',
        ),
        InfoStep(
          icon: Icons.currency_bitcoin,
          title: 'Variação de câmbio (LBTC)',
          description:
              'Ao escolher receber em LBTC, o valor final pode variar devido à cotação do momento da conversão. Você pode receber mais ou menos que o calculado.',
        ),
        InfoStep(
          icon: Icons.receipt_long,
          title: 'Sobre as taxas',
          description:
              'As taxas variam conforme o valor da transação. Valores menores têm taxas fixas, valores maiores têm taxas percentuais decrescentes.',
        ),
      ],
      footerBuilder:
          (closeOverlay) => SecondaryButton(
            text: 'Ver detalhes das taxas',
            onPressed: () {
              closeOverlay();
              context.push('/pix/fees');
            },
          ),
    );
  }

  Widget _buildInstructionText(BuildContext context) {
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
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final depositAmount = ref.watch(depositAmountProvider);
    final validation = ref.watch(depositValidationProvider);

    final isButtonEnabled = depositAmount > 0 && validation.isValid;

    return Padding(
      padding: EdgeInsets.only(right: 8, left: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructionText(context),
          SizedBox(height: 10),
          AssetSelectorWidget(),
          SizedBox(height: 10),
          PixValueInputWidget(),
          SizedBox(height: 16),
          TransactionDisplayWidget(),
          SizedBox(height: 16),
          SlideToConfirmButton(
            onSlideComplete: () => _onSlideComplete(context),
            text: 'Gerar QR Code',
            isLoading: _isLoading,
            isEnabled: isButtonEnabled,
          ),
          SizedBox(height: 120),
        ],
      ),
    );
  }
}
