import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/domain/entities/asset.dart' as domain;
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/infra/storage/asset_catalog_impl.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesFavouriteAssetsStore', () {
    Future<SharedPreferencesFavouriteAssetsStore> store(
      Map<String, Object> values,
    ) async {
      SharedPreferences.setMockInitialValues(values);
      return SharedPreferencesFavouriteAssetsStore(
        prefs: await SharedPreferences.getInstance(),
      );
    }

    test('a saved L-BTC favourite loads back', () async {
      final favourites = await store({});

      await favourites.save(const [domain.Asset.lbtc, domain.Asset.btc]);

      expect(await favourites.load(), const [
        domain.Asset.lbtc,
        domain.Asset.btc,
      ]);
    });

    test('a favourite saved as "Bitcoin L2" by an earlier version loads as '
        'L-BTC', () async {
      final favourites = await store({
        'favorite_assets': ['Bitcoin L2', 'Bitcoin'],
      });

      expect(await favourites.load(), const [
        domain.Asset.lbtc,
        domain.Asset.btc,
      ]);
    });
  });

  group('FavoriteAssetsNotifier', () {
    test('a saved L-BTC favourite loads back', () async {
      SharedPreferences.setMockInitialValues({});
      final first = FavoriteAssetsNotifier();
      await pumpEventQueue();
      first.setFavorites(const [Asset.lbtc, Asset.usdt]);
      await pumpEventQueue();

      final second = FavoriteAssetsNotifier();
      await pumpEventQueue();

      expect(second.state, const [Asset.lbtc, Asset.usdt]);
    });

    test('a favourite saved as "Bitcoin L2" by an earlier version loads as '
        'L-BTC', () async {
      SharedPreferences.setMockInitialValues({
        'favorite_assets': ['Bitcoin L2', 'USDt'],
      });
      final favourites = FavoriteAssetsNotifier();
      await pumpEventQueue();

      expect(favourites.state, const [Asset.lbtc, Asset.usdt]);
    });
  });
}
