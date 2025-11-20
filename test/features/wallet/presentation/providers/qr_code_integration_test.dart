import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/qr_validation_service.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/amount_detection_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

void main() {
  group('QR Code Integration Tests', () {
    group('Complete QR Flow - Valid Cases', () {
      test(
        'Liquid BIP21 with asset ID and amount - should validate and detect',
        () {
          const qrData =
              'liquidnetwork:lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?amount=0.00026312&label=Send%20to%20BTC%20address&assetid=6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';

          // Step 1: Validate
          final validationResult = QrValidationService.validateQrData(qrData);
          expect(
            validationResult.isValid,
            true,
            reason: 'Liquid BIP21 should be valid',
          );

          // Step 2: Detect amount
          final amountResult = AmountDetectionService.detectAmount(
            validationResult.cleanedData!,
          );
          expect(
            amountResult.hasAmount,
            true,
            reason: 'Should detect amount from BIP21',
          );
          expect(
            amountResult.amountInSats,
            26312,
            reason: 'Should extract correct satoshi amount',
          );
          expect(
            amountResult.asset,
            Asset.lbtc,
            reason: 'Should identify L-BTC asset',
          );
        },
      );

      test('Bitcoin BIP21 with amount - should validate and detect', () {
        const qrData =
            'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=0.001&label=Payment';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(validationResult.isValid, true);

        final amountResult = AmountDetectionService.detectAmount(
          validationResult.cleanedData!,
        );
        expect(amountResult.hasAmount, true);
        expect(amountResult.amountInSats, 100000);
        expect(amountResult.asset, Asset.btc);
        expect(amountResult.label, 'Payment');
      });

      test('Lightning invoice with value - should validate and detect', () {
        const qrData =
            'lnbc500u1p53etmlpp5wrrnh9lvr0ed4zvs6khdeyff9nl05r9udmej9sv07x7jnwa98uzqdql2djkuepqw3hjqsj5gvsxzerywfjhxuccqzylxqyp2xqsp56h4m2g04mpw4lfcx7au86h3cajhxj2mysjatlvfzm6cryzqac5tq9qxpqysgqn78d8dnkm8z76nywktl5yz66pzdcf9s27scjgr5c9rferjjjge4pg8rtkg6wp622u4yvvqw0xessyfu3jl9yynjzjnac4jyqx7s65zqpu48hu2';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(validationResult.isValid, true);

        final amountResult = AmountDetectionService.detectAmount(
          validationResult.cleanedData!,
        );
        expect(amountResult.hasAmount, true);
        expect(amountResult.amountInSats, 50000); // 500 uBTC
        expect(amountResult.asset, Asset.btc);
      });

      test('Plain Bitcoin address - should validate without amount', () {
        const qrData = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(validationResult.isValid, true);

        final amountResult = AmountDetectionService.detectAmount(
          validationResult.cleanedData!,
        );
        expect(amountResult.hasAmount, false);
      });
    });

    group('Complete QR Flow - Invalid Cases', () {
      test('BOLTZ invoice without value - should reject in validation', () {
        const qrData =
            'lnbc1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpl2pkx2ctnv5sxxmmwwd5kgetjypeh2ursdae8g6twvus8g6rfwvs8qun0dfjkxaq8rkx3yf5tcsyz3d73gafnh3cax9rn449d9p5uxz9ezhhypd0elx87sjle52x86fux2ypatgddc6k63n7erqz25le42c4u4ecky03ylcqca784w';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(validationResult.isValid, false);
        expect(validationResult.errorMessage, contains('BOLTZ'));
        expect(validationResult.errorMessage, contains('sem valor'));
      });

      test('Lightning with special symbols - should reject in validation', () {
        const qrData = 'user₿@domain.com';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(validationResult.isValid, false);
        expect(validationResult.errorMessage, contains('símbolos especiais'));
      });

      test('BIP 353 phoenixwallet - should reject in validation', () {
        const qrData = 'user@phoenixwallet.me';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(validationResult.isValid, false);
        expect(validationResult.errorMessage, contains('BIP 353'));
      });

      test('Empty QR data - should reject', () {
        const qrData = '';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(validationResult.isValid, false);
        expect(validationResult.errorMessage, contains('vazio'));
      });

      test('Unrecognized format - should reject', () {
        const qrData = 'random-invalid-data-12345';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(validationResult.isValid, false);
        expect(validationResult.errorMessage, contains('não reconhecido'));
      });
    });

    group('Edge Cases and Special Scenarios', () {
      test('Lightning with lightning: prefix - should strip and validate', () {
        const qrData =
            'lightning:lnbc100u1p0xlkhkpp5test123456789qwertyuiopasdfghjklzxcvbnm';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(validationResult.isValid, true);
        expect(
          validationResult.cleanedData,
          'lnbc100u1p0xlkhkpp5test123456789qwertyuiopasdfghjklzxcvbnm',
        );

        final amountResult = AmountDetectionService.detectAmount(
          validationResult.cleanedData!,
        );
        // Should detect amount from the invoice
        expect(amountResult.hasAmount, true);
        expect(amountResult.amountInSats, 10000); // 100 uBTC
      });

      test('Liquid USDT - should detect correct asset', () {
        const qrData =
            'liquidnetwork:lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?amount=100&assetid=ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(validationResult.isValid, true);

        final amountResult = AmountDetectionService.detectAmount(
          validationResult.cleanedData!,
        );
        expect(amountResult.asset, Asset.usdt);
        expect(amountResult.hasAmount, true);
      });

      test('Bitcoin BIP21 with zero amount - should not have amount', () {
        const qrData =
            'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=0';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(validationResult.isValid, true);

        final amountResult = AmountDetectionService.detectAmount(
          validationResult.cleanedData!,
        );
        expect(amountResult.hasAmount, false);
      });

      test('Liquid with liquid: prefix - should work same as liquidnetwork:', () {
        const qrData =
            'liquid:lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?amount=0.001';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(validationResult.isValid, true);

        final amountResult = AmountDetectionService.detectAmount(
          validationResult.cleanedData!,
        );
        expect(amountResult.hasAmount, true);
        expect(amountResult.asset, Asset.lbtc);
      });

      test('walletofsatoshi LNURL - should be accepted', () {
        const qrData = 'user@walletofsatoshi.com';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(validationResult.isValid, true);
      });
    });

    group('Real World Examples', () {
      test('Example 1: Liquid payment request from documentation', () {
        const qrData =
            'liquidnetwork:lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?amount=0.00026312&label=Send%20to%20BTC%20address&assetid=6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(
          validationResult.isValid,
          true,
          reason: 'Real Liquid BIP21 example should be valid',
        );

        final amountResult = AmountDetectionService.detectAmount(qrData);
        expect(amountResult.hasAmount, true, reason: 'Should detect amount');
        expect(
          amountResult.amountInSats,
          26312,
          reason: 'Should match amount from example',
        );
        expect(amountResult.asset, Asset.lbtc, reason: 'Should be L-BTC');
      });

      test('Example 2: BOLTZ invoice from documentation', () {
        const qrData =
            'lnbc500u1p53etmlpp5wrrnh9lvr0ed4zvs6khdeyff9nl05r9udmej9sv07x7jnwa98uzqdql2djkuepqw3hjqsj5gvsxzerywfjhxuccqzylxqyp2xqsp56h4m2g04mpw4lfcx7au86h3cajhxj2mysjatlvfzm6cryzqac5tq9qxpqysgqn78d8dnkm8z76nywktl5yz66pzdcf9s27scjgr5c9rferjjjge4pg8rtkg6wp622u4yvvqw0xessyfu3jl9yynjzjnac4jyqx7s65zqpu48hu2';

        final validationResult = QrValidationService.validateQrData(qrData);
        expect(
          validationResult.isValid,
          true,
          reason: 'BOLTZ invoice with value should be valid',
        );

        final amountResult = AmountDetectionService.detectAmount(qrData);
        expect(
          amountResult.hasAmount,
          true,
          reason: 'Should detect 50000 sats',
        );
        expect(amountResult.amountInSats, 50000);
      });
    });
  });
}
