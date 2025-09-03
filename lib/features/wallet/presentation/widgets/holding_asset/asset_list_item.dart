import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/wallet/data/models/holding_asset/asset_page_data.dart';

class AssetListItem extends StatelessWidget {
  final AssetPageData asset;
  final VoidCallback onTap;

  const AssetListItem({Key? key, required this.asset, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildAssetIcon(),
            SizedBox(width: 12),
            _buildAssetInfo(),
            _buildAssetValues(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: asset.iconColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          asset.iconText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAssetInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            asset.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            asset.amount,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetValues() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          asset.value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          asset.percentage,
          style: TextStyle(
            color: asset.isPositive ? Colors.green : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
