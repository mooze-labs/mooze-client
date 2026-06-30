import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_onboarding_service_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/receive_pix_screen.dart';
import 'package:mooze_mobile/features/pix/send_pix/presentation/screens/send_pix_tab_screen.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/first_time_pix_dialog.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_limits_info_dialog.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_down_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

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
    final t = AppLocalizations.of(context);
    InfoOverlay.show(
      context,
      title: t.pix_info_title,
      steps: [
        InfoStep(
          icon: Icons.schedule,
          title: t.pix_info_processing_title,
          description: t.pix_info_processing_body,
        ),
        InfoStep(
          icon: Icons.currency_bitcoin,
          title: t.pix_info_lbtc_variation_title,
          description: t.pix_info_lbtc_variation_body,
        ),
        InfoStep(
          icon: Icons.receipt_long,
          title: t.pix_info_fees_title,
          description: t.pix_info_fees_body,
        ),
      ],
      footerBuilder:
          (closeOverlay) => SecondaryButton(
            text: t.pix_info_fees_button,
            onPressed: () {
              closeOverlay();
              context.push('/pix/fees');
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
              color: context.colors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colors.primaryColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: context.colors.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: context.colors.textSecondary,
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: t.pix_main_tab_receive),
                Tab(text: t.pix_main_tab_send),
              ],
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
