import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/di/providers/pix_onboarding_service_provider.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/receive/presentation/screens/recive_pix_screen.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/send/send_pix_tab_screen.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/first_time_pix_dialog.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/pix_limits_info_dialog.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_down_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class PixMainScreen extends ConsumerStatefulWidget {
  const PixMainScreen({super.key});

  @override
  ConsumerState<PixMainScreen> createState() => _PixMainScreenState();
}

class _PixMainScreenState extends ConsumerState<PixMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeAccess();
    });
  }

  Future<void> _checkFirstTimeAccess() async {
    final onboardingService = ref.read(pixOnboardingServiceProvider);

    // Verifica se já viu o dialog
    if (!onboardingService.hasSeenFirstTimeDialog() && mounted) {
      final accepted = await FirstTimePixDialog.show(context);

      if (accepted == true && mounted) {
        // Marca como visto localmente
        await onboardingService.markFirstTimeDialogAsSeen();

        // Mostra o segundo dialog com informações sobre limites
        if (mounted) {
          await PixLimitsInfoDialog.show(context);
        }

        // TODO: Quando houver API, descomentar para sincronizar com backend
        // await onboardingService.submitTermsAcceptance();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PIX'),
        centerTitle: true,
        actions: [
          ApiDownIndicatorIcon(
            onRetry: () {
              // TODO: Invalidar providers quando necessário
            },
          ),
          OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
          IconButton(
            onPressed: () => _showPixInfo(context),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [Tab(text: 'Receber'), Tab(text: 'Enviar')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [ReceivePixScreen(), SendPixTabScreen()],
            ),
          ),
        ],
      ),
    );
  }
}
