import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/app/di/wallet_cleanup_hooks.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/shared/infra/db/providers.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/database_test_helpers.dart';

class _MockCore extends Mock implements MoozeCore {}

/// Exposes a [Ref] so a test can invoke `buildPixCleanupHook` exactly as the
/// wallet delete/import flow does.
final _refProbe = Provider<Ref>((ref) => ref);

/// Pins the wallet-isolation contract for PIX data: the cleanup sweep that
/// `buildPixCleanupHook` runs on wallet delete/import empties the core
/// stores and the legacy drift tables, and drops the cached controller.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => registerFallbackValue(PixFlagDto.tutorialShown));

  late AppDatabase db;
  late _MockCore core;
  late List<FavoritePayerDto> payers;

  setUp(() {
    db = buildInMemoryDatabase();
    core = _MockCore();
    payers = [
      FavoritePayerDto(
        id: BigInt.one,
        label: 'Previous wallet payer',
        cpf: '52998224725',
        maskedCpf: '529.982.247-25',
      ),
    ];
    when(() => core.favoritePayersList()).thenAnswer((_) async => payers);
    when(() => core.favoritePayersClear()).thenAnswer((_) async {
      payers = [];
    });
    when(() => core.pixClearDeposits()).thenAnswer((_) async {});
    when(() => core.pixFlagReset(flag: any(named: 'flag')))
        .thenAnswer((_) async {});
  });
  tearDown(() async => db.close());

  Future<ProviderContainer> container() async {
    SharedPreferences.setMockInitialValues({
      'hasSeenPixTutorial': true,
      'pix_favorite_payers': '[]',
    });
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(sp),
        moozeCoreProvider.overrideWith((_) async => core),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('buildPixCleanupHook clears the core PIX stores and every flag',
      () async {
    final c = await container();

    await buildPixCleanupHook(c.read(_refProbe))();

    verify(() => core.pixClearDeposits()).called(1);
    verify(() => core.favoritePayersClear()).called(1);
    for (final flag in PixFlagDto.values) {
      verify(() => core.pixFlagReset(flag: flag)).called(1);
    }
  });

  test('buildPixCleanupHook also clears the legacy drift and prefs data',
      () async {
    final c = await container();
    await db.insertFavoritePayer(
      FavoritePayerEntriesCompanion.insert(label: 'A', cpf: '52998224725'),
    );

    await buildPixCleanupHook(c.read(_refProbe))();

    expect(await db.getAllFavoritePayers(), isEmpty);
    final sp = c.read(sharedPreferencesProvider);
    expect(sp.containsKey('hasSeenPixTutorial'), isFalse);
    expect(sp.containsKey('pix_favorite_payers'), isFalse);
  });

  test(
    'buildPixCleanupHook invalidates the live controller (same session, no '
    'in-memory leak)',
    () async {
      final c = await container();

      // Previous wallet's favorites, cached in the controller.
      expect(await c.read(favoritePayersControllerProvider.future),
          hasLength(1));

      await buildPixCleanupHook(c.read(_refProbe))();

      expect(
        await c.read(favoritePayersControllerProvider.future),
        isEmpty,
        reason: 'previous wallet favorites must not survive cleanup in memory',
      );
    },
  );
}
