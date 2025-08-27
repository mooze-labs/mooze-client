import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

import 'asset_filter_entity.dart';

class FilterByAsset extends StatefulWidget {
  final List<AssetEntity> assets;
  final List<String> selectedAssetIds;
  final ValueChanged<List<String>> onSelectionChanged;

  const FilterByAsset({
    Key? key,
    required this.assets,
    required this.selectedAssetIds,
    required this.onSelectionChanged,
  }) : super(key: key);

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
    final selectedIds =
        _selectedAssets.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key.id)
            .toList();
    widget.onSelectionChanged(selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          widget.assets.map((asset) {
            final isSelected = _selectedAssets[asset] ?? false;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAssets[asset] = !isSelected;
                });
                _notifySelectionChange();
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double totalWidth = constraints.maxWidth;
                  const double totalSpacing = 2 * 10;
                  final double itemWidth = (totalWidth - totalSpacing) / 3;
                  return Container(
                    width: itemWidth,
                    height: 47,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color:
                          isSelected
                              ? AppColors.primaryColor.withValues(alpha: 0.3)
                              : Colors.grey,
                      border:
                          isSelected
                              ? Border.all(
                                color: AppColors.primaryColor,
                                width: 2,
                              )
                              : null,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          asset.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
    );
  }
}
