import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';
import 'package:mooze_mobile/app/di/wallet_cleanup_hooks.dart';
import 'package:mooze_mobile/features/support/presentations/srcreens/support_screen.dart';
import 'package:mooze_mobile/features/support/presentations/widgets/user_id_loading_skeleton.dart';
import 'package:mooze_mobile/infra/core/mooze_api_client.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/shared/network/providers.dart';
import 'package:mooze_mobile/shared/user/entities.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/user/services/user_id_storage_service.dart';
import 'package:mooze_mobile/shared/user/services/user_level_storage_service.dart';
import 'package:mooze_mobile/shared/user/services/user_service.dart';
import 'package:mooze_mobile/shared/user/services/user_service_impl.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockCore extends Mock implements MoozeCore {}

/// The user API. Each `getUser` counts, and answers with [answer].
class _Users implements UserService {
  _Users(this.answer);

  final Future<Either<String, User>> Function() answer;
  int calls = 0;

  @override
  TaskEither<String, User> getUser() {
    calls++;
    return TaskEither(answer);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

User _user(String id) => User(
  id: id,
  verificationLevel: 0,
  allowedSpending: 0,
  dailySpending: 0,
  spendingLevel: 0,
  levelProgress: 0,
  valuesToReceive: const {},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(HttpMethodDto.get_));

  group('the user service keeps the support id', () {
    late _MockCore core;
    late SharedPreferences prefs;
    late UserServiceImpl service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      core = _MockCore();
      final Dio dio = MoozeApiClient(
        () async => core,
      ).dio(baseUrl: 'https://api.test');
      service = UserServiceImpl(
        dio,
        UserLevelStorageService(prefs),
        idStorage: UserIdStorageService(prefs),
      );
    });

    void respond(int status, String body) {
      when(
        () => core.apiRequest(
          method: any(named: 'method'),
          path: any(named: 'path'),
          jsonBody: any(named: 'jsonBody'),
        ),
      ).thenAnswer((_) async => ApiResponseDto(status: status, body: body));
    }

    // Any screen that reads the user saves the id, so the support screen
    // has it even if the account is blocked before the user opens it.
    test('an answer of /users/me saves the id', () async {
      respond(200, '''
{"data":{"user_id":"u-123","verification_level":1,"allowed_spending":1000,
"daily_spending":10,"spending_level":1,"level_progress":0.5}}''');

      await service.getUser().run();

      expect(UserIdStorageService(prefs).read(), 'u-123');
    });

    test('the user service of the app saves the id', () async {
      respond(200, '''
{"data":{"user_id":"u-789","verification_level":1,"allowed_spending":1000,
"daily_spending":10,"spending_level":1,"level_progress":0.5}}''');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authenticatedClientProvider.overrideWithValue(
            MoozeApiClient(() async => core).dio(baseUrl: 'https://api.test'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(userServiceProvider).getUser().run();

      expect(UserIdStorageService(prefs).read(), 'u-789');
    });

    test('a refused /users/me keeps the saved id', () async {
      await UserIdStorageService(prefs).save('u-123');
      respond(403, '{"error":"FORBIDDEN"}');

      final result = await service.getUser().run();

      expect(result.isLeft(), isTrue);
      expect(UserIdStorageService(prefs).read(), 'u-123');
    });
  });

  group('support screen', () {
    Future<_Users> open(
      WidgetTester tester, {
      required Map<String, Object> saved,
      required Future<Either<String, User>> Function() answer,
    }) async {
      SharedPreferences.setMockInitialValues(saved);
      final prefs = await SharedPreferences.getInstance();
      final users = _Users(answer);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            userServiceProvider.overrideWithValue(users),
            isUsingCacheProvider.overrideWithValue(false),
          ],
          child: MaterialApp(
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) =>
                Theme(data: AppTheme.darkTheme(context), child: child!),
            home: const SupportScreen(),
          ),
        ),
      );
      return users;
    }

    // The id never changes, so a saved id shows at once: offline, or when
    // the API refuses a blocked account, the screen does not wait on a
    // request that cannot answer.
    testWidgets('shows the saved id at once, with no request', (tester) async {
      final users = await open(
        tester,
        saved: {'user_support_id': 'u-123'},
        answer: () => Completer<Either<String, User>>().future,
      );
      await tester.pump();

      expect(find.text('u-123'), findsOneWidget);
      expect(find.byType(UserIdLoadingSkeleton), findsNothing);
      expect(users.calls, 0);
    });

    testWidgets('without a saved id, it asks the API and shows the answer', (
      tester,
    ) async {
      final users = await open(
        tester,
        saved: {},
        answer: () async => Right(_user('u-456')),
      );
      await tester.pumpAndSettle();

      expect(find.text('u-456'), findsOneWidget);
      expect(users.calls, 1);
    });
  });

  // The id belongs to the wallet. A new or imported wallet has another
  // user, so it must not show the id of the old one.
  test('removing the wallet forgets the support id', () async {
    SharedPreferences.setMockInitialValues({'user_support_id': 'u-123'});
    final prefs = await SharedPreferences.getInstance();

    for (final hook in buildLegacyCleanupHooks()) {
      try {
        await hook();
      } catch (_) {
        // Other hooks clear the secure storage, which has no platform
        // here. Each hook is independent.
      }
    }

    expect(prefs.getString('user_support_id'), isNull);
  });
}
