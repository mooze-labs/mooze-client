import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mooze_mobile/features/settings/data/repositories/bitcoin_settings_repository_impl.dart';
import 'package:mooze_mobile/features/settings/data/repositories/liquid_settings_repository_impl.dart';

void main() {
  group('BitcoinSettingsRepository', () {
    late BitcoinSettingsRepository repository;

    setUp(() {
      repository = BitcoinSettingsRepository();
    });

    group('setNodeUrl', () {
      test('should save node URL successfully', () async {
        SharedPreferences.setMockInitialValues({});

        final result =
            await repository.setNodeUrl('electrum.example.com:50002').run();

        result.fold(
          (error) => fail('Expected Right, got Left: $error'),
          (_) {
            // success
          },
        );
      });
    });

    group('getNodeUrl', () {
      test('should return saved node URL', () async {
        SharedPreferences.setMockInitialValues(
          {'bitcoin_node_url': 'electrum.example.com:50002'},
        );

        final result = await repository.getNodeUrl().run();

        result.fold(
          (error) => fail('Expected Right, got Left: $error'),
          (url) => expect(url, 'electrum.example.com:50002'),
        );
      });

      test('should return empty string when no URL is saved', () async {
        SharedPreferences.setMockInitialValues({});

        final result = await repository.getNodeUrl().run();

        result.fold(
          (error) => fail('Expected Right, got Left: $error'),
          (url) => expect(url, ''),
        );
      });
    });

    group('roundtrip', () {
      test('should persist and retrieve URL correctly', () async {
        SharedPreferences.setMockInitialValues({});

        await repository.setNodeUrl('custom-node.com:443').run();
        final result = await repository.getNodeUrl().run();

        result.fold(
          (error) => fail('Expected Right, got Left: $error'),
          (url) => expect(url, 'custom-node.com:443'),
        );
      });
    });
  });

  group('LiquidSettingsRepository', () {
    late LiquidSettingsRepository repository;

    setUp(() {
      repository = LiquidSettingsRepository();
    });

    group('setNodeUrl', () {
      test('should save node URL successfully', () async {
        SharedPreferences.setMockInitialValues({});

        final result =
            await repository.setNodeUrl('liquid.example.com:465').run();

        result.fold(
          (error) => fail('Expected Right, got Left: $error'),
          (_) {
            // success
          },
        );
      });
    });

    group('getNodeUrl', () {
      test('should return saved node URL', () async {
        SharedPreferences.setMockInitialValues(
          {'liquid_node_url': 'liquid.example.com:465'},
        );

        final result = await repository.getNodeUrl().run();

        result.fold(
          (error) => fail('Expected Right, got Left: $error'),
          (url) => expect(url, 'liquid.example.com:465'),
        );
      });

      test('should return default URL when no value is saved', () async {
        SharedPreferences.setMockInitialValues({});

        final result = await repository.getNodeUrl().run();

        result.fold(
          (error) => fail('Expected Right, got Left: $error'),
          (url) => expect(url, 'blockstream.info:465'),
        );
      });
    });

    group('roundtrip', () {
      test('should persist and retrieve URL correctly', () async {
        SharedPreferences.setMockInitialValues({});

        await repository.setNodeUrl('custom-liquid.com:465').run();
        final result = await repository.getNodeUrl().run();

        result.fold(
          (error) => fail('Expected Right, got Left: $error'),
          (url) => expect(url, 'custom-liquid.com:465'),
        );
      });
    });
  });
}
