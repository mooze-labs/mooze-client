// lib/pix/presentation/widgets/asset_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/dropdownburron.dart';

class AssetSelectorWidget extends StatelessWidget {
  final String? selectedAsset;
  final List<String> assets;
  final ValueChanged<String?> onAssetChanged;

  // Constants - Colors
  static const Color _backgroundColor = Color(0xFF0A0A0A);
  static const Color _primaryColor = Color(0xFFEA1E63);

  const AssetSelectorWidget({
    Key? key,
    required this.selectedAsset,
    required this.assets,
    required this.onAssetChanged,
  }) : super(key: key);

  Widget _buildAssetIcon(String asset) {
    return Image.asset(
      'assets/images/logos/depix.png',
      width: 16,
      height: 16,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingLabelDropdown<String>(
      label: 'Selecione um ativo',
      value: selectedAsset,
      items: assets,
      onChanged: onAssetChanged,
      itemIconBuilder: _buildAssetIcon,
      itemLabelBuilder: (item) => item,
      borderColor: _primaryColor,
      backgroundColor: _backgroundColor,
    );
  }
}
