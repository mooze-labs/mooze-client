import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_input_provider.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_asset_dropdown.dart';

class SwapAssetCard extends ConsumerWidget {
  TextEditingController amountController;

  SwapAssetCard({super.key, required this.amountController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: SendAssetDropdown(),
                ),
                Expanded(
                  child: TextField(
                    controller: amountController,
                    onChanged: (value) {
                      ref
                          .read(swapInputNotifierProvider.notifier)
                          .changeSendAssetSatoshiAmount(int.parse(value));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: ReceiveAssetDropdown(),
                ),
                Expanded(
                  child: TextField(
                    controller: amountController,
                    onChanged: (value) {
                      ref
                          .read(swapInputNotifierProvider.notifier)
                          .changeRecvAssetSatoshiAmount(int.parse(value));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
