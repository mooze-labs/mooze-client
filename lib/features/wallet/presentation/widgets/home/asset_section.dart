import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/all_assets/all_assets_screen.dart';
import 'asset_graph_card.dart';
import 'section_header.dart';

class AssetSection extends StatelessWidget {
  const AssetSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          onAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllAssetsScreen()),
            );
          },
          title: "Ativos",
          actionDescription: "Ver mais",
        ),
        const SizedBox(height: 16),
        const AssetCardList(),
        const SizedBox(height: 32),
      ],
    );
  }
}
