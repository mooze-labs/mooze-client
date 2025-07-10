import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/pix/pix.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/receive/amount_input.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/wallet/activity.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/wallet/wallet.dart';

import '../providers/index_navigation_bar.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(indexNavigationBarProvider);

    return Scaffold(
      body: switch (index) {
        0 => const WalletScreen(),
        1 => const PixScreen(),
        2 => const ActivityScreen(),
        3 => const ReceiveAmountInputScreen(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
