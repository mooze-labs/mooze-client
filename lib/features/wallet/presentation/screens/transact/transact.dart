import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/core/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/transact/widgets/input_amount_display.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/bottom_nav_bar.dart';
import 'widgets/numpad_keyboard.dart';
import 'widgets/action_buttons_row.dart';

import 'providers.dart';

class TransactScreen extends ConsumerWidget {
  const TransactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final selectedAsset = ref.watch(selectedAssetProvider);

    return DefaultTabController(
      initialIndex: selectedTab,
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 60,
                child: TabBar(
                  tabs: [
                    Tab(text: 'DePix'),
                    Tab(text: 'BTC'),
                    Tab(text: 'USDt'),
                  ],
                  onTap: (index) {
                    ref.read(selectedTabProvider.notifier).state = index;
                    // Reset both input providers when switching tabs
                    ref.read(satoshiInputProvider.notifier).state = 0;
                    ref.read(fiatInputProvider.notifier).state = 0.0;
                    ref.read(fiatInputStringProvider.notifier).state = '';
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child:
                      selectedAsset == Asset.btc
                          ? SatoshiAmountDisplay()
                          : FiatAmountDisplay(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child:
                    selectedAsset == Asset.btc
                        ? IntegerNumpadKeyboard()
                        : DecimalNumpadKeyboard(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ActionButtonsRow(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(),
      ),
    );
  }
}
