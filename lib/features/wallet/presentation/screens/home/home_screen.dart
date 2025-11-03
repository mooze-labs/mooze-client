import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_provider.dart';
import 'package:mooze_mobile/shared/widgets/wallet_header_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/asset_section.dart';
import 'package:mooze_mobile/shared/widgets/update_notification_widget.dart';
import 'package:mooze_mobile/providers/update_provider.dart';

import '../../widgets/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _configureSystemUi();

    final isLoadingData = ref.watch(isLoadingDataProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => _refreshData(),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LogoHeader(),
                      WalletHeaderWidget(),
                      UpdateNotificationWidget(),
                      const SizedBox(height: 15),
                      _buildActionButtons(),
                      const SizedBox(height: 32),
                      AssetSection(),
                      TransactionSection(),
                      SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
            if (isLoadingData)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _loadInitialData() {
    final favoriteAssets = ref.read(favoriteAssetsProvider);

    final assetCacheNotifier = ref.read(
      assetPriceHistoryCacheProvider.notifier,
    );
    final transactionCacheNotifier = ref.read(
      transactionHistoryCacheProvider.notifier,
    );
    final updateNotifier = ref.read(updateNotifierProvider.notifier);

    for (final asset in favoriteAssets) {
      assetCacheNotifier.fetchAssetPriceHistoryInitial(asset);
      ref.read(balanceProvider(asset));
    }

    transactionCacheNotifier.fetchTransactionsInitial();

    updateNotifier.checkForUpdates();
  }

  Future<void> _refreshData() async {
    try {
      final favoriteAssets = ref.read(favoriteAssetsProvider);
      final allAssets = ref.read(allAssetsProvider);

      for (final asset in allAssets) {
        ref.invalidate(balanceProvider(asset));
      }

      ref.invalidate(transactionHistoryProvider);

      await Future.wait([
        ref
            .read(assetPriceHistoryCacheProvider.notifier)
            .refresh(favoriteAssets),
        ref.read(transactionHistoryCacheProvider.notifier).refresh(),
      ]);

      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    } catch (e) {
      debugPrint('Erro durante refresh: $e');
    }
  }
}

Widget _buildActionButtons() {
  return Column(
    children: [
      Row(
        children: [
          Expanded(child: ReceiveButton()),
          const SizedBox(width: 8),
          Expanded(child: SendButton()),
        ],
      ),
    ],
  );
}

void _configureSystemUi() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
}
