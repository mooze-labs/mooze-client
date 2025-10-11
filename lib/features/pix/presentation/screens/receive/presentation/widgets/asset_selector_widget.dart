import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/dropdown_button.dart';
import '../../../../providers.dart';

const _possibleAssets = [Asset.btc, Asset.depix];

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
      items: _possibleAssets,
      onChanged: (asset) {
        ref.read(selectedAssetProvider.notifier).state = (asset ?? Asset.depix);
      },
      itemIconBuilder: (asset) => _buildAssetIcon(asset),
      itemLabelBuilder: (asset) => asset.name,
      borderColor: Theme.of(context).colorScheme.primary,
    );
  }
}
