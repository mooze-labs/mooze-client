import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/app/di/wallet_cleanup_hooks.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/favorite_payers/data/datasources/favorite_payers_local_datasource.dart';
import 'package:mooze_mobile/features/favorite_payers/data/repositories/favorite_payers_repository_impl.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/shared/infra/db/providers.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/database_test_helpers.dart';

/// Exposes a [Ref] so a test can invoke `buildPixCleanupHook` exactly as the
/// wallet delete/import flow does.
final _refProbe = Provider<Ref>((ref) => ref);

/// Pins the wallet-isolation contract for favorite payers: the cleanup sweep
/// invoked by `buildPixCleanupHook` on wallet delete/import empties the table,
/// so a freshly imported/next wallet can never inherit the previous wallet's
/// saved CPFs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  setUp(() => db = buildInMemoryDatabase());
  tearDown(() async => db.close());

  test('repository.clearAll (cleanup sweep) wipes every payer', () async {
    final repo = FavoritePayersRepositoryImpl(
      FavoritePayersLocalDataSource(db),
    );
    await repo.save(const FavoritePayer(label: 'A', cpf: '52998224725'));
    await repo.save(const FavoritePayer(label: 'B', cpf: '11144477735'));
    expect(await repo.getAll(), hasLength(2));

    await repo.clearAll();

    expect(
      await repo.getAll(),
      isEmpty,
      reason: 'an imported/next wallet must not inherit favorite payers',
    );
  });

  test('deleteAllFavoritePayers DAO wipes the table', () async {
    final ds = FavoritePayersLocalDataSource(db);
    await ds.insert('A', '52998224725');
    await ds.insert('B', '11144477735');

    final removed = await db.deleteAllFavoritePayers();

    expect(removed, 2);
    expect(await db.getAllFavoritePayers(), isEmpty);
  });

  test(
    'a rebuilt controller after cleanup starts empty (provider invalidation)',
    () async {
      // Seed the previous wallet's data.
      final ds = FavoritePayersLocalDataSource(db);
      await ds.insert('Previous wallet payer', '52998224725');

      // Cleanup sweep (what delete/import runs before the new session).
      await ds.clearAll();

      // A fresh container models the new wallet session reading state anew.
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(favoritePayersControllerProvider.future),
        isEmpty,
        reason: 'new wallet session must observe an empty favorites list',
      );
    },
  );

  test(
    'buildPixCleanupHook invalidates the live controller (same session, no '
    'in-memory leak)',
    () async {
      // The real app keeps a single root ProviderScope across delete→reimport,
      // so this models the actual leak risk: a non-autoDispose controller that
      // already cached the previous wallet's list in memory.
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(sp),
        ],
      );
      addTearDown(container.dispose);

      // Previous wallet saves a favorite — now cached in the controller.
      final notifier = container.read(favoritePayersControllerProvider.notifier);
      await container.read(favoritePayersControllerProvider.future);
      await notifier.save(label: 'Previous wallet payer', cpf: '52998224725');
      expect(container.read(favoritePayersControllerProvider).value, hasLength(1));

      // Run the actual wallet-cleanup hook (the delete/import integration point).
      await buildPixCleanupHook(container.read(_refProbe))();

      // DB wiped AND cached controller invalidated → re-reading in the SAME
      // container yields an empty list (no previous-wallet data resurfaces).
      expect(
        await container.read(favoritePayersControllerProvider.future),
        isEmpty,
        reason: 'previous wallet favorites must not survive cleanup in memory',
      );
    },
  );
}
