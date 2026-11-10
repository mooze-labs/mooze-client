import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/filter_glass_widgets.dart';

import 'asset_filter_entity.dart';

class FilterByAsset extends StatefulWidget {
  final List<AssetEntity> assets;
  final List<String> selectedAssetIds;
  final ValueChanged<List<String>> onSelectionChanged;

  const FilterByAsset({
    super.key,
    required this.assets,
    required this.selectedAssetIds,
    required this.onSelectionChanged,
  });

  @override
  State<FilterByAsset> createState() => _FilterByAssetState();
}

class _FilterByAssetState extends State<FilterByAsset> {
  late Map<AssetEntity, bool> _selectedAssets;

  @override
  void initState() {
    super.initState();
    final shouldSelectAll = widget.selectedAssetIds.isEmpty;
    _selectedAssets = {
      for (var asset in widget.assets)
        asset: shouldSelectAll || widget.selectedAssetIds.contains(asset.id),
    };
  }

  void _notifySelectionChange() {
    final selectedIds = _selectedAssets.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key.id)
        .toList();
    widget.onSelectionChanged(selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: widget.assets.map((asset) {
        final isSelected = _selectedAssets[asset] ?? false;
        return FilterChipPill(
          label: asset.name,
          selected: isSelected,
          onTap: () {
            setState(() {
              _selectedAssets[asset] = !isSelected;
            });
            _notifySelectionChange();
          },
        );
      }).toList(),
    );
  }
}
