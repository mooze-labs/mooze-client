import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/amount_detection_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

void main() {
  group('AmountDetectionService', () {
    group('Lightning Invoice Amount Detection', () {
      test('should extract amount from invoice with milli-bitcoin (m)', () {
        // 0.5 mBTC = 50000 sats
        const invoice = 'lnbc500m1p0xlkhkpp5test';

        final result = AmountDetectionService.detectAmount(invoice);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 50000000);
        expect(result.asset, Asset.btc);
      });

      test('should extract amount from invoice with micro-bitcoin (u)', () {
        // 500 uBTC = 50000 sats
        const invoice = 'lnbc500u1p0xlkhkpp5test';

        final result = AmountDetectionService.detectAmount(invoice);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 50000);
        expect(result.asset, Asset.btc);
      });

      test('should extract amount from invoice with nano-bitcoin (n)', () {
        // 50000 nBTC = 5000 sats
        const invoice = 'lnbc50000n1p0xlkhkpp5test';

        final result = AmountDetectionService.detectAmount(invoice);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 5000);
        expect(result.asset, Asset.btc);
      });

      test('should extract amount from invoice with pico-bitcoin (p)', () {
        // 50000000 pBTC = 5000 sats
        const invoice = 'lnbc50000000p1p0xlkhkpp5test';

        final result = AmountDetectionService.detectAmount(invoice);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 5000);
        expect(result.asset, Asset.btc);
      });

      test('should detect invoice without amount', () {
        const invoice = 'lnbc1p0xlkhkpp5test';

        final result = AmountDetectionService.detectAmount(invoice);

        expect(result.hasAmount, false);
        // Asset may be null or btc depending on implementation
        // The key is that hasAmount is false
      });

      test('should handle real BOLTZ invoice with value', () {
        const invoice =
            'lnbc500u1p53etmlpp5wrrnh9lvr0ed4zvs6khdeyff9nl05r9udmej9sv07x7jnwa98uzqdql2djkuepqw3hjqsj5gvsxzerywfjhxuccqzylxqyp2xqsp56h4m2g04mpw4lfcx7au86h3cajhxj2mysjatlvfzm6cryzqac5tq9qxpqysgqn78d8dnkm8z76nywktl5yz66pzdcf9s27scjgr5c9rferjjjge4pg8rtkg6wp622u4yvvqw0xessyfu3jl9yynjzjnac4jyqx7s65zqpu48hu2';

        final result = AmountDetectionService.detectAmount(invoice);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 50000); // 500 uBTC = 50000 sats
        expect(result.asset, Asset.btc);
      });
    });

    group('Bitcoin BIP21 Amount Detection', () {
      test('should extract amount from Bitcoin BIP21', () {
        const bip21 =
            'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=0.001';

        final result = AmountDetectionService.detectAmount(bip21);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 100000); // 0.001 BTC = 100000 sats
        expect(result.asset, Asset.btc);
      });

      test('should extract amount with label and message', () {
        const bip21 =
            'bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa?amount=0.5&label=Donation&message=Thank%20you';

        final result = AmountDetectionService.detectAmount(bip21);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 50000000); // 0.5 BTC = 50000000 sats
        expect(result.asset, Asset.btc);
        expect(result.label, 'Donation');
        expect(result.message, 'Thank you');
      });

      test('should handle Bitcoin BIP21 without amount', () {
        const bip21 = 'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';

        final result = AmountDetectionService.detectAmount(bip21);

        expect(result.hasAmount, false);
        expect(result.asset, Asset.btc);
      });

      test('should handle fractional satoshi amounts', () {
        const bip21 =
            'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=0.00000001';

        final result = AmountDetectionService.detectAmount(bip21);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 1); // 1 satoshi
      });
    });

    group('Liquid Network BIP21 Amount Detection', () {
      test('should extract amount and asset ID from Liquid BIP21', () {
        const liquidBip21 =
            'liquidnetwork:lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?amount=0.00026312&label=Send%20to%20BTC%20address&assetid=6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';

        final result = AmountDetectionService.detectAmount(liquidBip21);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 26312); // 0.00026312 BTC
        expect(result.asset, Asset.lbtc); // L-BTC asset ID
        expect(result.label, 'Send to BTC address');
      });

      test('should detect USDT asset ID on Liquid', () {
        const liquidBip21 =
            'liquidnetwork:lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?amount=100&assetid=ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2';

        final result = AmountDetectionService.detectAmount(liquidBip21);

        expect(result.hasAmount, true);
        expect(result.asset, Asset.usdt); // USDT asset ID
      });

      test('should handle Liquid BIP21 with liquid: prefix', () {
        const liquidBip21 =
            'liquid:lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?amount=0.001';

        final result = AmountDetectionService.detectAmount(liquidBip21);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 100000);
        expect(result.asset, Asset.lbtc);
      });

      test('should handle Liquid BIP21 with asset ID but no amount', () {
        const liquidBip21 =
            'liquidnetwork:lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?assetid=6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';

        final result = AmountDetectionService.detectAmount(liquidBip21);

        expect(result.hasAmount, false);
        expect(result.asset, Asset.lbtc);
      });

      test('should default to L-BTC for unknown asset IDs', () {
        const liquidBip21 =
            'liquidnetwork:lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?amount=0.001&assetid=unknownassetid123';

        final result = AmountDetectionService.detectAmount(liquidBip21);

        expect(result.hasAmount, true);
        expect(result.asset, Asset.lbtc); // Default to L-BTC
      });
    });

    group('Query Parameters Extraction', () {
      test('should extract amount from plain address with query params', () {
        const address =
            'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=0.002';

        final result = AmountDetectionService.detectAmount(address);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 200000);
        expect(result.asset, Asset.btc);
      });

      test('should detect Liquid from lq1 address with query params', () {
        const address =
            'lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t?amount=0.001';

        final result = AmountDetectionService.detectAmount(address);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 100000);
        expect(result.asset, Asset.lbtc);
      });

      test('should detect Liquid from VJL address with query params', () {
        const address =
            'VJLCzH7NXR4xbD5jMqZmLz8yGxE6SqYk3P?amount=0.5&assetid=6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';

        final result = AmountDetectionService.detectAmount(address);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 50000000);
        expect(result.asset, Asset.lbtc);
      });

      test('should handle URL encoded label and message', () {
        const address =
            'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=0.001&label=My%20Payment&message=Thank%20you%20for%20your%20purchase';

        final result = AmountDetectionService.detectAmount(address);

        expect(result.hasAmount, true);
        expect(result.label, 'My Payment');
        expect(result.message, 'Thank you for your purchase');
      });
    });

    group('Edge Cases', () {
      test('should return empty result for empty string', () {
        const input = '';

        final result = AmountDetectionService.detectAmount(input);

        expect(result.hasAmount, false);
        expect(result.amountInSats, isNull);
        expect(result.asset, isNull);
      });

      test('should handle plain address without amount', () {
        const address = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';

        final result = AmountDetectionService.detectAmount(address);

        expect(result.hasAmount, false);
      });

      test('should handle zero amount', () {
        const bip21 =
            'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=0';

        final result = AmountDetectionService.detectAmount(bip21);

        expect(result.hasAmount, false);
      });

      test('should handle negative amount gracefully', () {
        const bip21 =
            'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=-0.001';

        final result = AmountDetectionService.detectAmount(bip21);

        // Should not have valid amount for negative values
        expect(result.hasAmount, false);
      });

      test('should handle invalid amount format', () {
        const bip21 =
            'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=invalid';

        final result = AmountDetectionService.detectAmount(bip21);

        expect(result.hasAmount, false);
      });

      test('should handle malformed URI', () {
        const malformed = 'bitcoin:?amount=0.001'; // Missing address

        final result = AmountDetectionService.detectAmount(malformed);

        // Should not crash, might return empty or with asset
        expect(result, isNotNull);
      });
    });

    group('Large Amount Handling', () {
      test('should handle large Bitcoin amount', () {
        const bip21 =
            'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=21';

        final result = AmountDetectionService.detectAmount(bip21);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 2100000000); // 21 BTC
      });

      test('should handle very small amount', () {
        const bip21 =
            'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=0.00000001';

        final result = AmountDetectionService.detectAmount(bip21);

        expect(result.hasAmount, true);
        expect(result.amountInSats, 1); // 1 satoshi
      });
    });
  });
}
