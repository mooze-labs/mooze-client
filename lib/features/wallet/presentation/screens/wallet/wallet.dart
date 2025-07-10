import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'widget.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Carteira',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const BalanceDisplay(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                WalletButtonBox(
                  label: "Enviar",
                  icon: Icons.arrow_outward,
                  onTap: () => Navigator.pushNamed(context, "/send_funds"),
                ),
                WalletButtonBox(
                  label: "Receber",
                  icon: Icons.call_received,
                  onTap: () => Navigator.pushNamed(context, "/receive_funds"),
                ),
                WalletButtonBox(
                  label: "Swap",
                  icon: Icons.swap_horiz,
                  onTap: () => Navigator.pushNamed(context, "/swap"),
                ),
              ],
            ),
            Column(
              children: [const BitcoinDisplay(), const StablecoinsDisplay()],
            ),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
