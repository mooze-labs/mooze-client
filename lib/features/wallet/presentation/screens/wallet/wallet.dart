import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/index_navigation_bar.dart';
import '../transact/transact.dart';
import 'activity.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(indexNavigationBarProvider);

    return index == 0 ? const TransactScreen() : const ActivityScreen();
  }
}
