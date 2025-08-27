import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/all_assets/widgets/asset_card_with_favorite.dart';

class AllAssetsScreen extends ConsumerWidget {
  const AllAssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAssets = ref.watch(allAssetsProvider);
    final favoriteAssets = ref.watch(favoriteAssetsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Todos os Ativos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acompanhe a cotação de todos os ativos disponíveis (${favoriteAssets.length}/2 favoritos)',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toque no ❤️ para definir seus ativos favoritos na tela principal',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 16,
                ),
                itemCount: allAssets.length,
                itemBuilder: (context, index) {
                  final asset = allAssets[index];
                  return AssetCardWithFavorite(asset: asset);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
