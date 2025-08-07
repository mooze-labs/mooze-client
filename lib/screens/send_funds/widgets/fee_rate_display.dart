import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_fee_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_fee_provider.dart';
import 'package:mooze_mobile/screens/send_funds/providers/send_user_input_provider.dart';
import 'package:shimmer/shimmer.dart';

class FeeRateDisplay extends ConsumerWidget {
  const FeeRateDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sendUserInput = ref.watch(sendUserInputProvider);
    final networkFeeProvider = ref.watch(networkFeeProviderProvider);

    if (sendUserInput.asset == null) {
      return const SizedBox.shrink();
    }

    return networkFeeProvider.when(
      data:
          (fees) => Row(
            children: [
              Text("Taxas de rede: "),
              Text(
                "${sendUserInput.networkFee?.absoluteFees} sats",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
      loading:
          () => Row(
            children: [
              Text("Taxas de rede: "),
              Shimmer.fromColors(
                baseColor: const Color.fromARGB(255, 77, 72, 72),
                highlightColor: const Color.fromARGB(255, 100, 95, 95),
                child: Container(
                  width: 100,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 116, 115, 115),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
      error:
          (e, stack) => Text(
            "Erro ao carregar taxas de rede",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
    );
  }
}
