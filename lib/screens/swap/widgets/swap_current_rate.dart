import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_input_provider.dart';

class SwapCurrentRate extends ConsumerWidget {
  const SwapCurrentRate({super.key, this.pegOperation = false});
  final bool pegOperation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapInput = ref.watch(swapInputNotifierProvider);

    if (swapInput.sendAsset == AssetCatalog.bitcoin ||
        swapInput.recvAsset == AssetCatalog.bitcoin) {

    }

    return Container();
  }
}
