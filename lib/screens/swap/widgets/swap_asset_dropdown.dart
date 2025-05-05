import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import '../providers/swap_input_provider.dart';

class SendAssetDropdown extends ConsumerWidget {
  const SendAssetDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapInput = ref.watch(swapInputNotifierProvider);
    final sendAsset = swapInput.sendAsset;

    return DropdownMenu(
      leadingIcon: Transform.scale(
        scale: 0.5,
        child: Image.asset(sendAsset.logoPath),
      ),
      label: Text("Você envia"),
      dropdownMenuEntries:
          AssetCatalog.liquidAssets
              .map(
                (asset) => DropdownMenuEntry(
                  value: asset,
                  label: asset.ticker,
                  leadingIcon: Image.asset(
                    asset.logoPath,
                    width: 24,
                    height: 24,
                  ),
                ),
              )
              .toList(),
      textAlign: TextAlign.center,
      initialSelection: sendAsset,
      onSelected: (Asset? asset) {
        if (asset != null) {
          ref.read(swapInputNotifierProvider.notifier).changeSendAsset(asset);
        }
      },
    );
  }
}

class ReceiveAssetDropdown extends ConsumerWidget {
  const ReceiveAssetDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapInput = ref.watch(swapInputNotifierProvider);
    final receiveAsset = swapInput.recvAsset;

    return DropdownMenu(
      leadingIcon: Transform.scale(
        scale: 0.5,
        child: Image.asset(receiveAsset.logoPath),
      ),
      label: Text("Você recebe"),
      dropdownMenuEntries:
          AssetCatalog.liquidAssets
              .map(
                (asset) => DropdownMenuEntry(
                  value: asset,
                  label: asset.ticker,
                  leadingIcon: Image.asset(
                    asset.logoPath,
                    width: 24,
                    height: 24,
                  ),
                ),
              )
              .toList(),
      textAlign: TextAlign.center,
      initialSelection: receiveAsset,
      onSelected: (Asset? asset) {
        if (asset != null) {
          ref.read(swapInputNotifierProvider.notifier).changeRecvAsset(asset);
        }
      },
    );
  }
}
