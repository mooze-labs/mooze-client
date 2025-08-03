import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/dropdown_button.dart';

import '../providers/selected_asset_provider.dart';

const Map<Asset, String> assetLogoNames = {
  Asset.btc: "bitcoin",
  Asset.depix: "depix",
  Asset.usdt: "tether"
};

class AssetSelectorWidget extends ConsumerWidget {
  const AssetSelectorWidget({super.key});

  Widget _buildAssetIcon(Asset asset) {
    return SvgPicture.asset(
        "assets/new_ui_wallet/assets/icons/asset/${assetLogoNames[asset]}.svg",
        width: 16,
        height: 16,
        fit: BoxFit.contain
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.read(selectedAssetProvider);
    return FloatingLabelDropdown<Asset>(
        label: "Selecione um ativo",
        value: selectedAsset,
        items: [Asset.btc, Asset.depix, Asset.usdt],
        onChanged: (val) => ref.read(selectedAssetProvider.notifier).state = val ?? Asset.btc,
        itemIconBuilder: _buildAssetIcon,
        itemLabelBuilder: (asset) => asset.name,
        borderColor: Theme.of(context).colorScheme.primary,
    );
  }
}