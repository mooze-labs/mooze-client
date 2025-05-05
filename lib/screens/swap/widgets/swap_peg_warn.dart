import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_input_provider.dart';

const pegInWarnText =
    """Atenção: essa é uma operação entre redes realizada pela Sideswap. Transações de peg-in só podem ser realizadas com no mínimo 0,00010000 BTC e demoram no mínimo 2 confirmações (~20 min) e podem demorar até 102 confirmações (~17 horas) em casos de baixa liquidez. Ao prosseguir, você confirma que está ciente dos tempos de confirmação e que os fundos podem demorar a ser transferidos.""";
const pegOutWarnText =
    """Atenção: essa é uma operação entre redes realizada pela Sideswap. Transações de peg-out só podem ser realizadas com no mínimo 0,00025000 BTC e podem demorar até 17 horas em casos de baixa liquidez. Ao prosseguir, você confirma que está ciente dos tempos de confirmação e que os fundos podem demorar a ser transferidos.""";

class SwapPegWarn extends ConsumerWidget {
  const SwapPegWarn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapInput = ref.watch(swapInputNotifierProvider);
    final pegIn = swapInput.sendAsset == AssetCatalog.bitcoin;

    if (swapInput.sendAsset == AssetCatalog.bitcoin ||
        swapInput.recvAsset == AssetCatalog.bitcoin) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.primary),
        ),
        child: Text(
          pegIn ? pegInWarnText : pegOutWarnText,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Container();
  }
}
