import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/providers/wallet/network_fee_provider.dart';
import 'package:mooze_mobile/screens/send_funds/providers/send_user_input_provider.dart';

class SelectableAssetsDropdown extends ConsumerWidget {
  const SelectableAssetsDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sendUserInput = ref.watch(sendUserInputProvider);

    return DropdownMenu<Asset>(
      onSelected: (Asset? asset) {
        ref.read(sendUserInputProvider.notifier).setAsset(asset);
        if (asset?.id == "btc") {
          ref.read(networkFeeProviderProvider.future).then((value) {
            ref
                .read(sendUserInputProvider.notifier)
                .setNetworkFee(value.bitcoinNormal);
          });
        } else {
          ref.read(networkFeeProviderProvider.future).then((value) {
            ref
                .read(sendUserInputProvider.notifier)
                .setNetworkFee(value.liquid);
          });
        }
        ref.read(sendUserInputProvider.notifier).setAmount(0);
      },
      initialSelection: sendUserInput.asset,
      dropdownMenuEntries:
          AssetCatalog.all
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
              .toList(),
      label: const Text("Selecione um ativo"),
      inputDecorationTheme:
          Theme.of(context).dropdownMenuTheme.inputDecorationTheme,
      menuStyle: Theme.of(context).dropdownMenuTheme.menuStyle,
      leadingIcon:
          (sendUserInput.asset != null)
              ? Transform.scale(
                scale: 0.5,
                child: Image.asset(
                  sendUserInput.asset!.logoPath,
                  width: 24,
                  height: 24,
                ),
              )
              : null,
    );
  }
}
