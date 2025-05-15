import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/wallet/network_fee_provider.dart';
import 'package:mooze_mobile/screens/send_funds/providers/send_user_input_provider.dart';

class FeeSelectionSegmentedButton extends ConsumerWidget {
  const FeeSelectionSegmentedButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sendUserInput = ref.watch(sendUserInputProvider);
    final networkFee = ref.watch(networkFeeProviderProvider);

    if (sendUserInput.asset?.id != "btc") {
      return const SizedBox.shrink();
    }

    return networkFee.when(
      data:
          (data) => SegmentedButton(
            segments: [
              ButtonSegment(value: 'fast', label: Text("Rápido")),
              ButtonSegment(value: 'normal', label: Text("Médio")),
              ButtonSegment(value: 'slow', label: Text("Lento")),
            ],
            selected: {
              if (sendUserInput.networkFee == data.bitcoinFast)
                'fast'
              else if (sendUserInput.networkFee == data.bitcoinNormal)
                'normal'
              else if (sendUserInput.networkFee == data.bitcoinSlow)
                'slow'
              else
                'normal',
            },
            onSelectionChanged: (value) {
              final selectedValue = value.first;
              final fee = switch (selectedValue) {
                'fast' => data.bitcoinFast,
                'normal' => data.bitcoinNormal,
                'slow' => data.bitcoinSlow,
                _ => data.bitcoinNormal,
              };
              ref.read(sendUserInputProvider.notifier).setNetworkFee(fee);
            },
          ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
