import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/dropdownburron.dart';
import 'package:mooze_mobile/features/send_funds/data/asset_fund_screen_data.dart';
import 'package:mooze_mobile/themes/app_colors.dart';


class AssetSelectorWidget extends StatelessWidget {
  final SendFundsScreenData? selectedAsset;
  final List<SendFundsScreenData> assets;
  final ValueChanged<SendFundsScreenData?> onAssetChanged;

  const AssetSelectorWidget({
    super.key,
    required this.selectedAsset,
    required this.assets,
    required this.onAssetChanged,
  });

  Widget _buildAssetIcon(SendFundsScreenData asset) {
    return SvgPicture.asset(
      asset.icon,
      width: 16,
      height: 16,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingLabelDropdown<SendFundsScreenData>(
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
