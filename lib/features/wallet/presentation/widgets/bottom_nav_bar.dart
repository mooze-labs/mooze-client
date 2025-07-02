import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../providers/index_navigation_bar.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(indexNavigationBarProvider);

    return NavigationBar(
      onDestinationSelected:
          (newIndex) =>
              ref.read(indexNavigationBarProvider.notifier).state = newIndex,
      selectedIndex: index,
      destinations: [
        NavigationDestination(icon: Icon(Icons.wallet), label: 'Carteira'),
        NavigationDestination(
          icon: SvgPicture.asset(
            "assets/images/icons/pix-brands-solid.svg",
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onPrimary,
              BlendMode.srcIn,
            ),
          ),
          label: 'PIX',
        ),
        NavigationDestination(icon: Icon(Icons.history), label: "Atividade"),
        NavigationDestination(icon: Icon(Icons.more_horiz), label: "Menu"),
      ],
      indicatorColor: Theme.of(context).colorScheme.primary,
    );
  }
}
