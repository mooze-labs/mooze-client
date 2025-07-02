import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/index_navigation_bar.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(indexNavigationBarProvider);

    return NavigationBar(
      onDestinationSelected: (index) {
        ref.read(indexNavigationBarProvider.notifier).state = index;
      },
      selectedIndex: index,
      destinations: [
        NavigationDestination(icon: Icon(Icons.swap_vert), label: 'Operar'),
        NavigationDestination(icon: Icon(Icons.history), label: 'Atividade'),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: 'Configurações',
        ),
      ],
      indicatorColor: Theme.of(context).colorScheme.primary,
    );
  }
}
