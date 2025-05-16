import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/providers/wallet/network_fee_provider.dart';
import 'package:mooze_mobile/screens/receive_pix/providers/pix_input_provider.dart';

class SelectableAssetsDropdown extends ConsumerWidget {
  const SelectableAssetsDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pixInput = ref.watch(pixInputProvider);

    return DropdownMenu<Asset>(
      onSelected: (Asset? asset) {
        if (asset == null) {
          ref
              .read(pixInputProvider.notifier)
              .updateAsset(AssetCatalog.getById("depix")!);
          return;
        }

        ref.read(pixInputProvider.notifier).updateAsset(asset);
      },
      initialSelection: pixInput.asset,
      dropdownMenuEntries:
          AssetCatalog.liquidAssets
              .map(
                (asset) => DropdownMenuEntry(
                  value: asset,
                  label: asset.name,
                  leadingIcon: Image.asset(
                    asset.logoPath,
                    width: 24,
                    height: 24,
                  ),
                ),
              )
              .where(
                (asset) =>
                    asset.value.id == "lbtc" || asset.value.id == "depix",
              )
              .toList(),
      label: const Text("Selecione um ativo"),
      inputDecorationTheme:
          Theme.of(context).dropdownMenuTheme.inputDecorationTheme,
      menuStyle: Theme.of(context).dropdownMenuTheme.menuStyle,
      leadingIcon:
          (pixInput.asset != null)
              ? Transform.scale(
                scale: 0.5,
                child: Image.asset(
                  pixInput.asset.logoPath,
                  width: 24,
                  height: 24,
                ),
              )
              : null,
    );
  }
}
