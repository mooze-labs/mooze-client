import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/qr_validation_service.dart';

void main() {
  group('QrValidationService', () {
    group('BOLTZ Invoice Validation', () {
      test('should accept BOLTZ invoice with value', () {
        // Invoice com 50000 sats (500u1)
        const invoice =
            'lnbc500u1p53etmlpp5wrrnh9lvr0ed4zvs6khdeyff9nl05r9udmej9sv07x7jnwa98uzqdql2djkuepqw3hjqsj5gvsxzerywfjhxuccqzylxqyp2xqsp56h4m2g04mpw4lfcx7au86h3cajhxj2mysjatlvfzm6cryzqac5tq9qxpqysgqn78d8dnkm8z76nywktl5yz66pzdcf9s27scjgr5c9rferjjjge4pg8rtkg6wp622u4yvvqw0xessyfu3jl9yynjzjnac4jyqx7s65zqpu48hu2';

        final result = QrValidationService.validateQrData(invoice);

        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
        expect(result.cleanedData, invoice);
      });

      test('should reject BOLTZ invoice without value', () {
        // Invoice sem valor (apenas 1 após lnbc)
        const invoice =
            'lnbc1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpl2pkx2ctnv5sxxmmwwd5kgetjypeh2ursdae8g6twvus8g6rfwvs8qun0dfjkxaq8rkx3yf5tcsyz3d73gafnh3cax9rn449d9p5uxz9ezhhypd0elx87sjle52x86fux2ypatgddc6k63n7erqz25le42c4u4ecky03ylcqca784w';

        final result = QrValidationService.validateQrData(invoice);

        expect(result.isValid, false);
        expect(result.errorMessage, contains('BOLTZ'));
        expect(result.errorMessage, contains('sem valor'));
      });

      test('should handle short invoice', () {
        const invoice = 'lnbc1p0xlkhkpp5test';

        final result = QrValidationService.validateQrData(invoice);

        // Short invoices are accepted but may not have amount
        expect(result.isValid, true);
      });
    });

    group('Lightning with Special Symbols', () {
      test('should reject Lightning address with ₿ symbol', () {
        const address = 'user₿@domain.com';

        final result = QrValidationService.validateQrData(address);

        expect(result.isValid, false);
        expect(result.errorMessage, contains('símbolos especiais'));
        expect(result.errorMessage, contains('₿'));
      });

      test('should reject Lightning address with # symbol', () {
        const address = 'user#tag@domain.com';

        final result = QrValidationService.validateQrData(address);

        expect(result.isValid, false);
        expect(result.errorMessage, contains('símbolos especiais'));
      });

      test('should reject Lightning address with \$ symbol', () {
        const address = 'user\$payment@domain.com';

        final result = QrValidationService.validateQrData(address);

        expect(result.isValid, false);
        expect(result.errorMessage, contains('símbolos especiais'));
      });
    });

    group('BIP 353 LNURL Validation', () {
      test('should reject phoenixwallet.me BIP 353', () {
        const address = 'user@phoenixwallet.me';

        final result = QrValidationService.validateQrData(address);

        expect(result.isValid, false);
        expect(result.errorMessage, contains('BIP 353'));
        expect(result.errorMessage, contains('não é suportado'));
      });

      test('should accept walletofsatoshi.com LNURL', () {
        const address = 'user@walletofsatoshi.com';

        final result = QrValidationService.validateQrData(address);

        expect(result.isValid, true);
        expect(result.cleanedData, address);
      });

      test('should reject generic LNURL with @ (not walletofsatoshi)', () {
        const address = 'lnurl1user@otherprovider.com';

        final result = QrValidationService.validateQrData(address);

        expect(result.isValid, false);
        expect(result.errorMessage, contains('suportado'));
      });
    });

    group('Liquid Network BIP21 Validation', () {
      test('should accept Liquid BIP21 with asset ID and amount', () {
        const liquidBip21 =
            'liquidnetwork:lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?amount=0.00026312&label=Send%20to%20BTC%20address&assetid=6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';

        final result = QrValidationService.validateQrData(liquidBip21);

        expect(result.isValid, true);
        expect(result.cleanedData, liquidBip21);
      });

      test('should accept Liquid BIP21 with only asset ID', () {
        const liquidBip21 =
            'liquidnetwork:lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?assetid=6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';

        final result = QrValidationService.validateQrData(liquidBip21);

        expect(result.isValid, true);
      });

      test('should accept Liquid BIP21 without asset ID', () {
        const liquidBip21 =
            'liquidnetwork:lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?amount=0.001';

        final result = QrValidationService.validateQrData(liquidBip21);

        expect(result.isValid, true);
      });

      test('should reject Liquid BIP21 with empty address', () {
        const liquidBip21 =
            'liquidnetwork:?amount=0.001&assetid=6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';

        final result = QrValidationService.validateQrData(liquidBip21);

        expect(result.isValid, false);
        expect(result.errorMessage, contains('Endereço Liquid inválido'));
      });

      test('should accept liquid: prefix', () {
        const liquidBip21 =
            'liquid:lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?amount=0.001';

        final result = QrValidationService.validateQrData(liquidBip21);

        expect(result.isValid, true);
      });
    });

    group('Bitcoin BIP21 Validation', () {
      test('should accept Bitcoin BIP21 with amount', () {
        const bitcoinBip21 =
            'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=0.001';

        final result = QrValidationService.validateQrData(bitcoinBip21);

        expect(result.isValid, true);
        expect(result.cleanedData, bitcoinBip21);
      });

      test('should accept Bitcoin BIP21 with label and message', () {
        const bitcoinBip21 =
            'bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa?amount=0.5&label=Donation&message=Thank%20you';

        final result = QrValidationService.validateQrData(bitcoinBip21);

        expect(result.isValid, true);
      });

      test('should reject Bitcoin BIP21 with empty address', () {
        const bitcoinBip21 = 'bitcoin:?amount=0.001';

        final result = QrValidationService.validateQrData(bitcoinBip21);

        expect(result.isValid, false);
        expect(result.errorMessage, contains('Endereço Bitcoin inválido'));
      });
    });

    group('Lightning Invoice Validation', () {
      test('should accept valid Lightning invoice', () {
        const invoice =
            'lnbc10u1p0xlkhkpp5test123456789qwertyuiopasdfghjklzxcvbnm';

        final result = QrValidationService.validateQrData(invoice);

        expect(result.isValid, true);
        expect(result.cleanedData, invoice);
      });

      test('should accept Lightning invoice with lightning: prefix', () {
        const invoice =
            'lightning:lnbc10u1p0xlkhkpp5test123456789qwertyuiopasdfghjklzxcvbnm';

        final result = QrValidationService.validateQrData(invoice);

        expect(result.isValid, true);
        // The service removes the lightning: prefix
        expect(
          result.cleanedData,
          'lnbc10u1p0xlkhkpp5test123456789qwertyuiopasdfghjklzxcvbnm',
        );
      });

      test('should reject very short Lightning invoice', () {
        const invoice = 'lnbc1p0xl';

        final result = QrValidationService.validateQrData(invoice);

        expect(result.isValid, false);
        expect(result.errorMessage, contains('muito curto'));
      });
    });

    group('Plain Address Validation', () {
      test('should accept Bitcoin bc1 address', () {
        const address = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';

        final result = QrValidationService.validateQrData(address);

        expect(result.isValid, true);
        expect(result.cleanedData, address);
      });

      test('should accept Bitcoin legacy address', () {
        const address = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa';

        final result = QrValidationService.validateQrData(address);

        expect(result.isValid, true);
      });

      test('should accept Bitcoin P2SH address', () {
        const address = '3J98t1WpEZ73CNmYviecrnyiWrnqRhWNLy';

        final result = QrValidationService.validateQrData(address);

        expect(result.isValid, true);
      });

      test('should accept Liquid lq1 address', () {
        const address =
            'lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t';

        final result = QrValidationService.validateQrData(address);

        expect(result.isValid, true);
      });

      test('should accept Liquid VJL address', () {
        const address = 'VJLCzH7NXR4xbD5jMqZmLz8yGxE6SqYk3P';

        final result = QrValidationService.validateQrData(address);

        expect(result.isValid, true);
      });
    });

    group('Invalid Data', () {
      test('should reject empty string', () {
        const data = '';

        final result = QrValidationService.validateQrData(data);

        expect(result.isValid, false);
        expect(result.errorMessage, contains('vazio'));
      });

      test('should reject unrecognized format', () {
        const data = 'random-invalid-qr-data-12345';

        final result = QrValidationService.validateQrData(data);

        expect(result.isValid, false);
        expect(result.errorMessage, contains('não reconhecido'));
      });
    });
  });
}
