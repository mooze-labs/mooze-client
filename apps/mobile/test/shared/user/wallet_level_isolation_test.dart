import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/user/entities.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/user/services/user_level_storage_service.dart';
import 'package:mooze_mobile/shared/user/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts `getUser()` invocations so a test can assert that
/// [userDataProvider] re-fetches when the auth chain rebuilds.
class _CountingUserService implements UserService {
  _CountingUserService(this.onGetUser);

  final void Function() onGetUser;

  @override
  TaskEither<String, User> getUser() {
    onGetUser();
    // Return Left so the test needs no concrete User fixture — it only
    // cares that a fetch happened.
    return TaskEither.left('stub');
  }

  @override
  TaskEither<String, bool> validateReferralCode(String referralCode) =>
      TaskEither.right(true);

  @override
  TaskEither<String, Unit> addReferral(String referralCode) =>
      TaskEither.right(unit);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Persisted verification level cleanup', () {
    test('clearVerificationLevel removes the wallet-scoped stored level',
        () async {
      SharedPreferences.setMockInitialValues({'user_verification_level': 2});
      final prefs = await SharedPreferences.getInstance();
      final service = UserLevelStorageService(prefs);

      expect(service.getStoredVerificationLevel(), 2);

      await service.clearVerificationLevel();

      expect(service.getStoredVerificationLevel(), isNull,
          reason: 'a new wallet must not inherit the previous level');
    });
  });

  group('userDataProvider reactivity (Wallet Levels & Limits isolation)', () {
    test(
        'refetches /users/me when the user service rebuilds on wallet change',
        () async {
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          // A fresh instance per build → invalidation produces a
          // non-identical value, so watchers recompute.
          userServiceProvider
              .overrideWith((ref) => _CountingUserService(() => calls++)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(userDataProvider.future);
      expect(calls, 1, reason: 'first read fetches once');

      // Simulate the auth chain rebuilding on wallet delete / import
      // (mnemonic → session → authenticatedClient → userService).
      container.invalidate(userServiceProvider);
      await container.read(userDataProvider.future);

      expect(calls, 2,
          reason: 'userDataProvider must refetch for the new wallet rather '
              'than serve the previous wallet cached result');
    });
  });
}
