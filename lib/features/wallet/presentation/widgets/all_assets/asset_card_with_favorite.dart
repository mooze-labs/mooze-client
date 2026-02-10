import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/asset_graph_card.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class AssetCardWithFavorite extends ConsumerWidget {
  final Asset asset;

  const AssetCardWithFavorite({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteAssetProvider(asset));

    return Stack(
      children: [
        AssetGraphCard(asset: asset),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              ref.read(favoriteAssetsProvider.notifier).toggleFavorite(asset);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
