import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mooze_mobile/features/settings/external/datasources/bitcoin_settings_local_datasource.dart';
import 'package:mooze_mobile/features/settings/external/datasources/liquid_settings_local_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

void main() {
  group('BitcoinSettingsLocalDataSource', () {
    late BitcoinSettingsLocalDataSource dataSource;

    setUp(() {
      dataSource = BitcoinSettingsLocalDataSource();
    });

    group('setNodeUrl', () {
      test('should save node URL successfully', () async {
        SharedPreferences.setMockInitialValues({});

        final result =
            await dataSource.setNodeUrl('electrum.example.com:50002');

        expect(result.isSuccess, true);
      });
    });

    group('getNodeUrl', () {
      test('should return saved node URL', () async {
        SharedPreferences.setMockInitialValues(
          {'bitcoin_node_url': 'electrum.example.com:50002'},
        );

        final result = await dataSource.getNodeUrl();

        result.fold(
          (url) => expect(url, 'electrum.example.com:50002'),
          (error) => fail('Expected Success, got Failure: $error'),
        );
      });

      test('should return empty string when no URL is saved', () async {
        SharedPreferences.setMockInitialValues({});

        final result = await dataSource.getNodeUrl();

        result.fold(
          (url) => expect(url, ''),
          (error) => fail('Expected Success, got Failure: $error'),
        );
      });
    });

    group('roundtrip', () {
      test('should persist and retrieve URL correctly', () async {
        SharedPreferences.setMockInitialValues({});

        await dataSource.setNodeUrl('custom-node.com:443');
        final result = await dataSource.getNodeUrl();

        result.fold(
          (url) => expect(url, 'custom-node.com:443'),
          (error) => fail('Expected Success, got Failure: $error'),
        );
      });
    });
  });

  group('LiquidSettingsLocalDataSource', () {
    late LiquidSettingsLocalDataSource dataSource;

    setUp(() {
      dataSource = LiquidSettingsLocalDataSource();
    });

    group('setNodeUrl', () {
      test('should save node URL successfully', () async {
        SharedPreferences.setMockInitialValues({});

        final result =
            await dataSource.setNodeUrl('liquid.example.com:465');

        expect(result.isSuccess, true);
      });
    });

    group('getNodeUrl', () {
      test('should return saved node URL', () async {
        SharedPreferences.setMockInitialValues(
          {'liquid_node_url': 'liquid.example.com:465'},
        );

        final result = await dataSource.getNodeUrl();

        result.fold(
          (url) => expect(url, 'liquid.example.com:465'),
          (error) => fail('Expected Success, got Failure: $error'),
        );
      });

      test('should return default URL when no value is saved', () async {
        SharedPreferences.setMockInitialValues({});

        final result = await dataSource.getNodeUrl();

        result.fold(
          (url) => expect(url, 'blockstream.info:465'),
          (error) => fail('Expected Success, got Failure: $error'),
        );
      });
    });

    group('roundtrip', () {
      test('should persist and retrieve URL correctly', () async {
        SharedPreferences.setMockInitialValues({});

        await dataSource.setNodeUrl('custom-liquid.com:465');
        final result = await dataSource.getNodeUrl();

        result.fold(
          (url) => expect(url, 'custom-liquid.com:465'),
          (error) => fail('Expected Success, got Failure: $error'),
        );
      });
    });
  });
}
