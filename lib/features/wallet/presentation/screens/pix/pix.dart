import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/bottom_nav_bar.dart';
import 'widgets.dart';

class PixScreen extends StatelessWidget {
  const PixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 60,
                child: AssetTabBar(),
              ),
              const SizedBox(height: 16),
              SelectOperationCard(
                icon: Icon(
                  Icons.arrow_downward,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                text: 'Receber',
                subtext: 'Gere um QR code PIX e receba criptoativos',
                onTap: () {},
              ),
              SelectOperationCard(
                icon: Icon(
                  Icons.arrow_upward,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                text: 'Sacar DePix',
                subtext: 'Receba um PIX em conta corrente ao enviar DePix',
                onTap: () {},
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }
}
