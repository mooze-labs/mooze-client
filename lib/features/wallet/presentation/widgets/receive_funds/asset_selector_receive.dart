import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/dropdown_button.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';

final selectedReceiveAssetProvider = StateProvider<Asset?>((ref) => Asset.btc);

class AssetSelectorReceive extends ConsumerWidget {
  const AssetSelectorReceive({super.key});

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
    final selectedAsset = ref.watch(selectedReceiveAssetProvider);
    final validationController = ref.read(
      receiveValidationControllerProvider.notifier,
    );

    return FloatingLabelDropdown<Asset>(
      label: "Selecione um ativo",
      value: selectedAsset,
      items: [Asset.btc, Asset.lbtc, Asset.depix, Asset.usdt],
      onChanged: (val) {
        ref.read(selectedReceiveAssetProvider.notifier).state =
            val ?? Asset.btc;
        validationController.validateAsset(val ?? Asset.btc);
      },
      itemIconBuilder: _buildAssetIcon,
      itemLabelBuilder: (asset) => asset.name,
      borderColor: Theme.of(context).colorScheme.primary,
    );
  }
}
