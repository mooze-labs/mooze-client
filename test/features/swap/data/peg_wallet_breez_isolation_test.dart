import 'package:flutter_test/flutter_test.dart';

import 'package:mooze_mobile/features/swap/data/repositories/peg_wallet_impl.dart';

/// Guards that keep peg-in funding out of Breez.
///
/// `WalletRepositoryImpl.buildOnchainBitcoinPaymentTransaction` and
/// `sendOnchainBitcoinPayment` both branch to Breez when the destination looks
/// like a Liquid address. That branch is correct for the send-funds screen and
/// a trapdoor for peg-in, which must always fund through BDK.
///
/// SideSwap returns `bc1…` for peg-in (verified live), so the branch is never
/// taken in practice — these tests make it a checked invariant instead of a
/// data-dependent accident.
void main() {
  group('Liquid address detection', () {
    test('recognises every Liquid address form that would route to Breez', () {
      // Mainnet confidential, mainnet unconfidential, testnet, regtest.
      const liquidAddresses = [
        'lq1qqgdcmfjrxkqc7ghpmg993pnwp4w4rmzvr0krykcvvkxvnr5r8vrrykpc0zm',
        'tlq1qq2hs8scrhpvltn5eqhr3jcqxu5m2xn0lkq4mhrqlvhq2yxrn7z0aqp',
        'ex1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4',
        'tex1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx',
        'el1qq2hs8scrhpvltn5eqhr3jcqxu5m2xn0lkq4mhrqlvhq2yxrn7z0aqp',
        'ert1qw508d6qejxtdg4y5r3zarvary0c5xw7kygt080',
      ];

      for (final address in liquidAddresses) {
        expect(
          PegWalletImpl.looksLikeLiquidAddressForTest(address),
          isTrue,
          reason: '$address must be rejected as a peg-in destination',
        );
      }
    });

    test('accepts the Bitcoin address forms SideSwap actually returns', () {
      // The first is a verbatim `peg_addr` from a live mainnet peg-in order.
      const bitcoinAddresses = [
        'bc1qmvl2pjc7q0rgv0hm0gadhfzn66hqxh8ft9p8g3quvhca6wysfj2svjwyxq',
        'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
        '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
        '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy',
        'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx',
      ];

      for (final address in bitcoinAddresses) {
        expect(
          PegWalletImpl.looksLikeLiquidAddressForTest(address),
          isFalse,
          reason: '$address is a valid peg-in destination',
        );
      }
    });

    test('is case- and whitespace-insensitive', () {
      // A mixed-case or padded address must not slip past the guard.
      expect(
        PegWalletImpl.looksLikeLiquidAddressForTest('  LQ1QQGDCMFJRX  '),
        isTrue,
      );
    });

    test('an empty destination is not mistaken for Liquid', () {
      // Empty is rejected earlier, by the orchestrator's own validation; the
      // guard must not claim it is a Liquid address.
      expect(PegWalletImpl.looksLikeLiquidAddressForTest(''), isFalse);
    });
  });
}
