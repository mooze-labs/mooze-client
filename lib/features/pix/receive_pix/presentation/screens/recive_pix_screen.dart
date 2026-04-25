import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_onboarding_service_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_validation_provider.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/first_time_pix_dialog.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_limits_info_dialog.dart';
import 'package:mooze_mobile/features/wallet/routes.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_unavailable_overlay.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/asset_selector_widget.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/info_tips_section.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/pix_value_input_widget.dart';

class ReceivePixScreen extends ConsumerStatefulWidget {
  const ReceivePixScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ReceivePixScreenState();
}

class _ReceivePixScreenState extends ConsumerState<ReceivePixScreen> {
  bool _hasShownFirstTimeDialog = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Receber PIX'),
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
          style: Theme.of(context).textTheme.labelLarge?.copyWith(height: 1.4),
          children: [
            TextSpan(
              text: 'Mooze',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: '.'),
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
      padding: const EdgeInsets.only(right: 8, left: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructionText(context),
          const SizedBox(height: 10),
          AssetSelectorWidget(),
          const SizedBox(height: 10),
          PixValueInputWidget(),
          const SizedBox(height: 12),
          const InfoTipsSection(
            tips: [
              InfoTip(
                icon: Icons.trending_up_rounded,
                text: 'Faça mais pagamentos para liberar novos limites',
                iconColor: Color(0xFF2A9D6B),
              ),
            ],
            maxTips: 1,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Avançar',
            onPressed: () => context.push('/pix/confirm'),
            isEnabled: isButtonEnabled,
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
