import 'package:flutter/material.dart';

class AssetSelector extends StatelessWidget {
  final String? selectedAssetId;
  final Map<String, Map<String, String>> assetDetails;
  final ValueChanged<String?> onChanged;

  const AssetSelector({
    Key? key,
    required this.selectedAssetId,
    required this.assetDetails,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full width of the screen
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD973C1), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true, // Ensures full-width dropdown
          value: selectedAssetId,
          dropdownColor: const Color(0xFF1E1E1E),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD973C1)),
          hint: const Text(
            "Selecione o ativo",
            style: TextStyle(color: Colors.white),
          ),
          style: const TextStyle(color: Colors.white),
          items: assetDetails.keys.map((assetId) {
            return DropdownMenuItem<String>(
              value: assetId,
              child: Row(
                children: [
                  Image.asset(
                    assetDetails[assetId]!['logo']!,
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    assetDetails[assetId]!['name']!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
