import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../consts.dart';

import 'asset_graph_card.dart';
import 'section_header.dart';

class AssetSection extends StatelessWidget {
  const AssetSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(onAction: () => (), title: "Ativos", actionDescription: "Ver mais"),
        const SizedBox(width: cardSpacing),
        AssetCardList(),
      ],
    );
  }
}
