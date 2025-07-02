import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/transact/widgets/input_amount_display.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/wallet/widget/bottom_nav_bar.dart';
import 'widgets/numpad_keyboard.dart';
import 'widgets/action_buttons_row.dart';
import 'providers/transact_input_provider.dart';

class TransactScreen extends ConsumerWidget {
  const TransactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentValue = ref.watch(satoshiInputProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SatoshiAmountDisplay(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: NumpadKeyboard(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ActionButtonsRow(),
            ),
            Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
