import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mooze_mobile/features/settings/domain/entities/account_unit.dart';
import 'package:mooze_mobile/features/settings/external/datasources/account_unit_local_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

void main() {
  late AccountUnitLocalDataSource dataSource;

  setUp(() {
    dataSource = AccountUnitLocalDataSource();
  });

  group('AccountUnitLocalDataSource', () {
    group('setAccountUnit', () {
      test('should save bitcoin account unit successfully', () async {
        SharedPreferences.setMockInitialValues({});

        final result = await dataSource.setAccountUnit(AccountUnit.bitcoin);

        expect(result.isSuccess, true);
      });

      test('should save satoshi account unit successfully', () async {
        SharedPreferences.setMockInitialValues({});

        final result = await dataSource.setAccountUnit(AccountUnit.satoshi);

        expect(result.isSuccess, true);
      });
    });

    group('getAccountUnit', () {
      test('should return bitcoin when saved', () async {
        SharedPreferences.setMockInitialValues({'account_unit': 'bitcoin'});

        final result = await dataSource.getAccountUnit();

        result.fold(
          (accountUnit) => expect(accountUnit, AccountUnit.bitcoin),
          (error) => fail('Expected Success, got Failure: $error'),
        );
      });

      test('should return satoshi when saved', () async {
        SharedPreferences.setMockInitialValues({'account_unit': 'satoshi'});

        final result = await dataSource.getAccountUnit();

        result.fold(
          (accountUnit) => expect(accountUnit, AccountUnit.satoshi),
          (error) => fail('Expected Success, got Failure: $error'),
        );
      });

      test('should return satoshi as default when no value is saved', () async {
        SharedPreferences.setMockInitialValues({});

        final result = await dataSource.getAccountUnit();

        result.fold(
          (accountUnit) => expect(accountUnit, AccountUnit.satoshi),
          (error) => fail('Expected Success, got Failure: $error'),
        );
      });

      test('should return satoshi for unknown values', () async {
        SharedPreferences.setMockInitialValues({'account_unit': 'unknown'});

        final result = await dataSource.getAccountUnit();

        result.fold(
          (accountUnit) => expect(accountUnit, AccountUnit.satoshi),
          (error) => fail('Expected Success, got Failure: $error'),
        );
      });
    });

    group('roundtrip', () {
      test('should persist and retrieve bitcoin correctly', () async {
        SharedPreferences.setMockInitialValues({});

        await dataSource.setAccountUnit(AccountUnit.bitcoin);
        final result = await dataSource.getAccountUnit();

        result.fold(
          (accountUnit) => expect(accountUnit, AccountUnit.bitcoin),
          (error) => fail('Expected Success, got Failure: $error'),
        );
      });
    });
  });
}
