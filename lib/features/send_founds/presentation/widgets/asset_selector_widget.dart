import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/dropdownburron.dart';
import 'package:mooze_mobile/features/send_founds/data/asset_data_screen.dart';
import 'package:mooze_mobile/themes/app_colors.dart';


class AssetSelectorWidget extends StatelessWidget {
  final SendFoundScreenData? selectedAsset;
  final List<SendFoundScreenData> assets;
  final ValueChanged<SendFoundScreenData?> onAssetChanged;

  const AssetSelectorWidget({
    super.key,
    required this.selectedAsset,
    required this.assets,
    required this.onAssetChanged,
  });

  Widget _buildAssetIcon(SendFoundScreenData asset) {
    return SvgPicture.asset(
      asset.icon,
      width: 16,
      height: 16,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingLabelDropdown<SendFoundScreenData>(
      label: 'Selecione um ativo',
      value: selectedAsset,
      items: assets,
      onChanged: onAssetChanged,
      itemIconBuilder: _buildAssetIcon,
      itemLabelBuilder: (asset) => asset.name,
      borderColor: Theme.of(context).colorScheme.primary,
    );
  }
}
