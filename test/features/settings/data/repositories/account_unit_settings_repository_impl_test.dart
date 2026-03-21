import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mooze_mobile/features/settings/data/repositories/account_unit_settings_repository_impl.dart';
import 'package:mooze_mobile/features/settings/domains/repositories/account_unit_settings_repository.dart';

void main() {
  late AccountUnitSettingsRepositoryImpl repository;

  setUp(() {
    repository = AccountUnitSettingsRepositoryImpl();
  });

  group('setAccountUnit', () {
    test('should save bitcoin account unit successfully', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await repository.setAccountUnit(AccountUnit.bitcoin).run();

      result.fold(
        (error) => fail('Expected Right, got Left: $error'),
        (_) {
          // success
        },
      );
    });

    test('should save satoshi account unit successfully', () async {
      SharedPreferences.setMockInitialValues({});

      final result =
          await repository.setAccountUnit(AccountUnit.satoshi).run();

      result.fold(
        (error) => fail('Expected Right, got Left: $error'),
        (_) {
          // success
        },
      );
    });
  });

  group('getAccountUnit', () {
    test('should return bitcoin when saved', () async {
      SharedPreferences.setMockInitialValues({'account_unit': 'bitcoin'});

      final result = await repository.getAccountUnit().run();

      result.fold(
        (error) => fail('Expected Right, got Left: $error'),
        (accountUnit) => expect(accountUnit, AccountUnit.bitcoin),
      );
    });

    test('should return satoshi when saved', () async {
      SharedPreferences.setMockInitialValues({'account_unit': 'satoshi'});

      final result = await repository.getAccountUnit().run();

      result.fold(
        (error) => fail('Expected Right, got Left: $error'),
        (accountUnit) => expect(accountUnit, AccountUnit.satoshi),
      );
    });

    test('should return satoshi as default when no value is saved', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await repository.getAccountUnit().run();

      result.fold(
        (error) => fail('Expected Right, got Left: $error'),
        (accountUnit) => expect(accountUnit, AccountUnit.satoshi),
      );
    });

    test('should return satoshi for unknown values', () async {
      SharedPreferences.setMockInitialValues({'account_unit': 'unknown'});

      final result = await repository.getAccountUnit().run();

      result.fold(
        (error) => fail('Expected Right, got Left: $error'),
        (accountUnit) => expect(accountUnit, AccountUnit.satoshi),
      );
    });
  });

  group('roundtrip', () {
    test('should persist and retrieve bitcoin correctly', () async {
      SharedPreferences.setMockInitialValues({});

      await repository.setAccountUnit(AccountUnit.bitcoin).run();
      final result = await repository.getAccountUnit().run();

      result.fold(
        (error) => fail('Expected Right, got Left: $error'),
        (accountUnit) => expect(accountUnit, AccountUnit.bitcoin),
      );
    });
  });
}
