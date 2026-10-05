import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/liquid_spend_wallet.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

// Expected strings are the exact `destination` values Breez Liquid SDK
// 0.12.4 returned for the "abandon … about" mnemonic on mainnet (receive
// indexes 1, 2 and 3). LWK must keep producing the same URIs so QR codes
// and payer wallets see no change after the Breez removal.
const _usdt =
    'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2';
const _lbtc =
    '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';

const _addr1 =
    'lq1qqfk0uw9vlmqlggzs7cxmw49x8ks37l87udspmpt3ssgxjrkqqlww63xvus3c5gaz89r2kd393c4fvurwxf06qj87y2kd3vsln';
const _addr2 =
    'lq1qq2hdcgt6y6t28k6l9s74slvs6hgr6pqnd3qe59r3e0fak9pm472rgnc79v53gksxyj8rzqp73qfdn356a95s2sj9ez3ezvvq0';
const _addr3 =
    'lq1qqfhg68lh4vy4sadwtqj7z57js7vkmfpqx6v6lpuu9ntf43dfs3w37ljcz02zsjmsnc38urw8wtq8usph3np65560aftdvr7rt';

void main() {
  group('liquidBip21 matches Breez output', () {
    test('asset without amount', () {
      expect(Asset.usdt.id, _usdt);
      expect(
        liquidBip21(_addr1, assetId: _usdt),
        'liquidnetwork:$_addr1?assetid=$_usdt',
      );
    });

    test('asset with amount puts amount first', () {
      expect(
        liquidBip21(_addr2, assetId: _usdt, amount: BigInt.from(1250000000)),
        'liquidnetwork:$_addr2?amount=12.50000000&assetid=$_usdt',
      );
    });

    test('L-BTC with amount puts assetid first', () {
      expect(Asset.lbtc.id, _lbtc);
      expect(
        liquidBip21(_addr3, assetId: _lbtc, amount: BigInt.from(1000)),
        'liquidnetwork:$_addr3?assetid=$_lbtc&amount=0.00001000',
      );
    });
  });

  group('bareLiquidAddress', () {
    test('keeps a bare address', () {
      expect(bareLiquidAddress(_addr1), _addr1);
    });

    test('strips scheme and query from a BIP21 URI', () {
      expect(
        bareLiquidAddress('liquidnetwork:$_addr2?amount=1.0&assetid=$_usdt'),
        _addr2,
      );
      expect(bareLiquidAddress('liquid:$_addr3'), _addr3);
    });

    test('trims whitespace', () {
      expect(bareLiquidAddress('  $_addr1\n'), _addr1);
    });
  });

  group('isLiquidDestination', () {
    test('accepts Liquid addresses and URIs', () {
      expect(isLiquidDestination(_addr1), isTrue);
      expect(
        isLiquidDestination('liquidnetwork:$_addr1?assetid=$_usdt'),
        isTrue,
      );
      expect(
        isLiquidDestination(
          'VJLCUu2hpcjPaTGMnAnTZXTTjc3ALaKNNq3Jo2wSGyuqNNmhJ9Qx4PWAYWzKNN6VcwoUmMX6MC9TaDVS',
        ),
        isTrue,
      );
    });

    test('rejects Bitcoin addresses', () {
      expect(
        isLiquidDestination('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq'),
        isFalse,
      );
      expect(
        isLiquidDestination('1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2'),
        isFalse,
      );
      expect(
        isLiquidDestination('3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy'),
        isFalse,
      );
    });
  });
}
