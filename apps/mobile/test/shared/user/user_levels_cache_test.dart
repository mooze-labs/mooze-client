import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';
import 'package:mooze_mobile/app/di/wallet_cleanup_hooks.dart';
import 'package:mooze_mobile/features/wallet_level/infra/datasources/wallet_levels_datasource.dart';
import 'package:mooze_mobile/features/wallet_level/infra/models/wallet_levels_response_model.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/providers/usecase_providers.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/screens/wallet_levels_screen.dart';
import 'package:mooze_mobile/infra/core/mooze_api_client.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';
import 'package:mooze_mobile/shared/network/providers.dart';
import 'package:mooze_mobile/shared/user/entities.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/user/services/user_service.dart';
import 'package:mooze_mobile/shared/widgets/user_level_card.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class _MockCore extends Mock implements MoozeCore {}

/// An answer of `/users/me`.
Map<String, dynamic> _userJson({int level = 1, double progress = 0.3}) => {
  'data': {
    'user_id': 'u-1',
    'verification_level': 1,
    'allowed_spending': 50000,
    'daily_spending': 1000,
    'spending_level': level,
    'level_progress': progress,
  },
};

/// The public table of the level limits.
const Map<String, dynamic> _tableJson = {
  'data': {
    'bronze': {'max_limit': 25000, 'min_limit': 2000},
    'silver': {'max_limit': 50000, 'min_limit': 25000},
    'gold': {'max_limit': 150000, 'min_limit': 50000},
    'diamond': {'max_limit': 300000, 'min_limit': 150000},
  },
};

User _user({int level = 1, double progress = 0.3}) =>
    User.fromJson(_userJson(level: level, progress: progress));

/// The user API. Each call counts and waits for its own answer.
class _Users implements UserService {
  final List<Completer<Either<String, User>>> answers = [];

  int get calls => answers.length;

  void answer(Either<String, User> value) => answers.last.complete(value);

  @override
  TaskEither<String, User> getUser() {
    final answer = Completer<Either<String, User>>();
    answers.add(answer);
    return TaskEither(() => answer.future);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The level table on the network. Each fetch counts and waits for its own
/// answer.
class _Table implements WalletLevelsDataSource {
  final List<Completer<WalletLevelsResponseModel>> answers = [];

  int get calls => answers.length;

  @override
  Future<WalletLevelsResponseModel> getWalletLevels() {
    final answer = Completer<WalletLevelsResponseModel>();
    answers.add(answer);
    return answer.future;
  }
}

/// Lets the answers that completed reach the providers.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(HttpMethodDto.get_));

  /// The saved answers on the device.
  Map<String, Object> saved({double progress = 0.3, bool table = true}) => {
    'user_data_cache': jsonEncode(_userJson(progress: progress)),
    if (table) 'wallet_levels_cache': jsonEncode(_tableJson),
  };

  Future<(ProviderContainer, _Users, _Table)> container(
    Map<String, Object> prefsValues,
  ) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    final users = _Users();
    final table = _Table();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        userServiceProvider.overrideWithValue(users),
        walletLevelsDataSourceProvider.overrideWithValue(table),
      ],
    );
    addTearDown(container.dispose);
    return (container, users, table);
  }

  group('user data', () {
    // The level screen and the limits open with what the device knows,
    // and the answer of the API replaces it without a loading state.
    test('a saved answer shows at once, and the answer of the API replaces '
        'it in the background', () async {
      final (c, users, _) = await container(saved(progress: 0.3));
      c.listen(userDataProvider, (_, _) {});

      final first = c.read(userDataProvider);
      expect(first.isLoading, isFalse);
      expect(first.value?.toNullable()?.levelProgress, 0.3);
      expect(users.calls, 1);

      users.answer(Right(_user(progress: 0.6)));
      await _settle();

      final next = c.read(userDataProvider);
      expect(next.isLoading, isFalse);
      expect(next.value?.toNullable()?.levelProgress, 0.6);
    });

    test('a failed refresh keeps the saved answer, with no error', () async {
      final (c, users, _) = await container(saved(progress: 0.3));
      c.listen(userDataProvider, (_, _) {});

      users.answer(const Left('offline'));
      await _settle();

      final state = c.read(userDataProvider);
      expect(state.hasError, isFalse);
      expect(state.value?.toNullable()?.levelProgress, 0.3);
    });

    // A new build, as after a payment, asks again. The late answer of the
    // old build must not replace the newer one.
    test('a late answer of an old build changes nothing', () async {
      final (c, users, _) = await container(saved(progress: 0.3));
      c.listen(userDataProvider, (_, _) {});
      final old = users.answers.last;

      c.invalidate(userDataProvider);
      c.read(userDataProvider);
      users.answer(Right(_user(progress: 0.6)));
      await _settle();
      old.complete(Right(_user(progress: 0.1)));
      await _settle();

      expect(c.read(userDataProvider).value?.toNullable()?.levelProgress, 0.6);
    });

    // After a wallet change the saved answer is gone, and the user of the
    // old wallet is still in memory while the new one loads. The levels
    // must wait, not show the old level.
    test('after a wallet change, the levels wait for the new user', () async {
      final (c, users, _) = await container(saved());
      c.listen(levelsProvider, (_, _) {});
      expect(c.read(levelsProvider).value?.spendingLevel, 1);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data_cache');
      c.invalidate(userDataProvider);
      await _settle();

      expect(c.read(levelsProvider).isLoading, isTrue);
      users.answer(Right(_user(level: 0)));
      await _settle();
      await _settle();
      expect(c.read(levelsProvider).value?.spendingLevel, 0);
    });

    test('without a saved answer, it waits for the API', () async {
      final (c, users, _) = await container({});
      c.listen(userDataProvider, (_, _) {});

      expect(c.read(userDataProvider).isLoading, isTrue);

      users.answer(Right(_user(progress: 0.5)));
      await _settle();
      expect(c.read(userDataProvider).value?.toNullable()?.levelProgress, 0.5);
    });
  });

  group('the user service', () {
    late _MockCore core;
    late SharedPreferences prefs;
    late List<Map<String, dynamic>> answers;

    setUp(() async {
      core = _MockCore();
      answers = [];
      when(
        () => core.apiRequest(
          method: any(named: 'method'),
          path: any(named: 'path'),
          jsonBody: any(named: 'jsonBody'),
        ),
      ).thenAnswer(
        (_) async =>
            ApiResponseDto(status: 200, body: jsonEncode(answers.removeAt(0))),
      );
    });

    ProviderContainer appContainer() {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authenticatedClientProvider.overrideWithValue(
            MoozeApiClient(() async => core).dio(baseUrl: 'https://api.test'),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('saves each answer of /users/me', () async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      answers.add(_userJson(level: 2, progress: 0.7));
      final c = appContainer();

      await c.read(userServiceProvider).getUser().run();

      final restored = jsonDecode(prefs.getString('user_data_cache')!);
      expect(User.fromJson(restored).spendingLevel, 2);
      expect(User.fromJson(restored).levelProgress, 0.7);
    });

    // A level change comes from an answer that the service already saved,
    // maybe asked by another screen. It shows here with no new request.
    test('a level change found by another screen shows with no new '
        'request', () async {
      SharedPreferences.setMockInitialValues({
        'user_data_cache': jsonEncode(_userJson(level: 0, progress: 0.9)),
        'user_verification_level': 0,
      });
      prefs = await SharedPreferences.getInstance();
      answers
        ..add(_userJson(level: 0, progress: 0.9))
        ..add(_userJson(level: 1, progress: 0.1));
      final c = appContainer();
      c.listen(userDataProvider, (_, _) {});
      // The refresh of the build takes the first answer.
      for (var i = 0; i < 50 && answers.length > 1; i++) {
        await _settle();
      }
      expect(answers, hasLength(1));
      await _settle();

      // Another screen, for example the support screen, reads the user.
      await c.read(userServiceProvider).getUser().run();
      await _settle();
      await _settle();

      final user = c.read(userDataProvider).value?.toNullable();
      expect(user?.spendingLevel, 1);
      expect(user?.levelProgress, 0.1);
      verify(
        () => core.apiRequest(
          method: any(named: 'method'),
          path: any(named: 'path'),
          jsonBody: any(named: 'jsonBody'),
        ),
      ).called(2);
    });
  });

  group('level table', () {
    test(
      'a saved table shows at once, and the fetched one replaces it',
      () async {
        final (c, _, table) = await container(saved());
        c.listen(walletLevelsRemoteProvider, (_, _) {});

        final first = c.read(walletLevelsRemoteProvider);
        expect(first.isLoading, isFalse);
        expect(first.value?.data['silver']?.maxLimit, 50000);
        expect(table.calls, 1);

        final changed = jsonDecode(jsonEncode(_tableJson));
        changed['data']['silver']['max_limit'] = 60000;
        table.answers.last.complete(
          WalletLevelsResponseModel.fromJson(changed),
        );
        await _settle();

        expect(
          c.read(walletLevelsRemoteProvider).value?.data['silver']?.maxLimit,
          60000,
        );
      },
    );

    test('a late table of an old build changes nothing', () async {
      final (c, _, table) = await container(saved());
      c.listen(walletLevelsRemoteProvider, (_, _) {});
      final old = table.answers.last;

      c.invalidate(walletLevelsRemoteProvider);
      c.read(walletLevelsRemoteProvider);
      final changed = jsonDecode(jsonEncode(_tableJson));
      changed['data']['silver']['max_limit'] = 60000;
      table.answers.last.complete(WalletLevelsResponseModel.fromJson(changed));
      await _settle();
      final stale = jsonDecode(jsonEncode(_tableJson));
      stale['data']['silver']['max_limit'] = 10;
      old.complete(WalletLevelsResponseModel.fromJson(stale));
      await _settle();

      expect(
        c.read(walletLevelsRemoteProvider).value?.data['silver']?.maxLimit,
        60000,
      );
    });

    test('a fetched table is saved for the next time', () async {
      final (c, _, table) = await container({});
      c.listen(walletLevelsRemoteProvider, (_, _) {});
      expect(c.read(walletLevelsRemoteProvider).isLoading, isTrue);

      table.answers.last.complete(
        WalletLevelsResponseModel.fromJson(_tableJson),
      );
      await _settle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('wallet_levels_cache'), isNotNull);
    });

    test('a failed refresh keeps the saved table, with no error', () async {
      final (c, _, table) = await container(saved());
      c.listen(walletLevelsRemoteProvider, (_, _) {});

      table.answers.last.completeError(Exception('offline'));
      await _settle();

      final state = c.read(walletLevelsRemoteProvider);
      expect(state.hasError, isFalse);
      expect(state.value?.data['silver']?.maxLimit, 50000);
    });

    test(
      'the levels and their limits come from what is saved, at once',
      () async {
        final (c, _, _) = await container(saved(progress: 0.3));
        c.listen(levelsProvider, (_, _) {});

        final levels = c.read(levelsProvider);
        expect(levels.isLoading, isFalse);
        expect(levels.value?.spendingLevel, 1);
        expect(levels.value?.levelProgress, 0.3);
        expect(levels.value?.currentLevelMaxLimit, 500);
      },
    );
  });

  group('levels screen', () {
    Future<(_Users, _Table)> open(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(saved(progress: 0.3));
      final prefs = await SharedPreferences.getInstance();
      final users = _Users();
      final table = _Table();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            userServiceProvider.overrideWithValue(users),
            walletLevelsDataSourceProvider.overrideWithValue(table),
            ensureAuthSessionProvider.overrideWith((ref) async => true),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('pt'),
            builder: (context, child) =>
                Theme(data: AppTheme.darkTheme(context), child: child!),
            home: const WalletLevelsScreen(),
          ),
        ),
      );
      return (users, table);
    }

    double progress(WidgetTester tester) => tester
        .widget<UserLevelCard>(find.byType(UserLevelCard))
        .currentProgress;

    // The screen opens with the saved level and progress. The answers of
    // the API arrive later and replace them, and no frame shows a loading
    // state in between.
    testWidgets('opens with the saved level, with no loading, and shows the '
        'new progress without a loading state', (tester) async {
      final (users, table) = await open(tester);

      expect(find.byType(Shimmer), findsNothing);
      expect(progress(tester), 0.3);

      users.answer(Right(_user(progress: 0.6)));
      table.answers.last.complete(
        WalletLevelsResponseModel.fromJson(_tableJson),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byType(Shimmer), findsNothing);
      }
      expect(progress(tester), 0.6);
    });

    // A pull asks the API again and waits for its answer.
    testWidgets('a pull to refresh asks for the user and the table again', (
      tester,
    ) async {
      final (users, table) = await open(tester);
      users.answer(Right(_user(progress: 0.3)));
      table.answers.last.complete(
        WalletLevelsResponseModel.fromJson(_tableJson),
      );
      await tester.pump();

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(users.calls, 2);
      expect(table.calls, 2);
      users.answer(Right(_user(progress: 0.8)));
      table.answers.last.complete(
        WalletLevelsResponseModel.fromJson(_tableJson),
      );
      await tester.pumpAndSettle();
      expect(progress(tester), 0.8);
    });
  });

  // The saved answer belongs to the user of the wallet. A new or imported
  // wallet must not show the level of the old one.
  test('removing the wallet forgets the saved user', () async {
    SharedPreferences.setMockInitialValues(saved());
    final prefs = await SharedPreferences.getInstance();

    for (final hook in buildLegacyCleanupHooks()) {
      try {
        await hook();
      } catch (_) {
        // Other hooks clear the secure storage, which has no platform
        // here. Each hook is independent.
      }
    }

    expect(prefs.getString('user_data_cache'), isNull);
  });
}
