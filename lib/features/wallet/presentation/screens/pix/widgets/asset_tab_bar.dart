import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class AssetTabBar extends ConsumerWidget {
  const AssetTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabBar(
      tabs: [Tab(text: "DePix"), Tab(text: "BTC")],
      onTap: (index) {
        ref.read(selectedTabProvider.notifier).state = index;
      },
    );
  }
}
