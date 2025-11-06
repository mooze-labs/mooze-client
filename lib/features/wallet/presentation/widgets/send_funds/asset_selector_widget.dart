import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/dropdown_button.dart';

import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/amount_provider.dart';
import '../../providers/send_funds/detected_amount_provider.dart';
import '../../providers/send_funds/address_controller_provider.dart';

void clearAllFields(WidgetRef ref) {
  final addressController = ref.read(addressControllerProvider);
  addressController.clear();

  ref.read(syncedAddressControllerProvider.notifier).clear();

  ref.invalidate(detectedAmountProvider);
}

class AssetSelectorWidget extends ConsumerWidget {
  const AssetSelectorWidget({super.key});

  Widget _buildAssetIcon(Asset asset) {
    return SvgPicture.asset(
      asset.iconPath,
      width: 16,
      height: 16,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.watch(selectedAssetProvider);
    return FloatingLabelDropdown<Asset>(
      label: "Selecione um ativo",
      value: selectedAsset,
      items: [Asset.btc, Asset.lbtc, Asset.depix, Asset.usdt],
      onChanged: (val) {
        if (val != null && val != selectedAsset) {
          clearAllFields(ref);

          ref.read(amountStateProvider.notifier).state = 0;
          ref.invalidate(detectedAmountProvider);

          ref.read(selectedAssetProvider.notifier).state = val;
        }
      },
      itemIconBuilder: _buildAssetIcon,
      itemLabelBuilder: (asset) => asset.name,
      borderColor: Theme.of(context).colorScheme.primary,
    );
  }
}
