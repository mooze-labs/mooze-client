import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/domain/services/address_chain_detector.dart';

void main() {
  late AddressChainDetector detector;

  setUp(() {
    detector = const AddressChainDetector();
  });

  group('stripUriScheme', () {
    test('returns address unchanged when no scheme is present', () {
      expect(
        detector.stripUriScheme('bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh'),
        'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
      );
    });

    test('strips bitcoin: scheme', () {
      expect(
        detector.stripUriScheme('bitcoin:bc1qabc'),
        'bc1qabc',
      );
    });

    test('strips bitcoin: scheme with query parameters', () {
      expect(
        detector.stripUriScheme('bitcoin:bc1qabc?amount=0.5&label=test'),
        'bc1qabc',
      );
    });

    test('strips liquidnetwork: scheme', () {
      expect(
        detector.stripUriScheme('liquidnetwork:lq1qaddr'),
        'lq1qaddr',
      );
    });

    test('trims surrounding whitespace', () {
      expect(detector.stripUriScheme('   bc1qabc   '), 'bc1qabc');
    });
  });

  group('detect', () {
    test('detects Bitcoin mainnet bech32', () {
      expect(detector.detect('bc1qxy2kgdyg'), [AddressChain.bitcoin]);
    });

    test('detects Bitcoin mainnet legacy P2PKH', () {
      expect(detector.detect('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'),
          [AddressChain.bitcoin]);
    });

    test('detects Bitcoin mainnet P2SH', () {
      expect(detector.detect('3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy'),
          [AddressChain.bitcoin]);
    });

    test('detects Bitcoin testnet bech32', () {
      expect(detector.detect('tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qccfmv3'),
          [AddressChain.bitcoin]);
    });

    test('detects Bitcoin testnet legacy', () {
      expect(detector.detect('mzBc4XEFSdzCDcTxAgf6EZXgsZWpztRhef'),
          [AddressChain.bitcoin]);
    });

    test('detects Liquid mainnet confidential bech32 (lq1)', () {
      expect(detector.detect('lq1qqg5acpr3ekg26ppwxh4z4qe9hsh'),
          [AddressChain.liquid]);
    });

    test('detects Liquid mainnet unconfidential segwit (ex1)', () {
      expect(detector.detect('ex1qsedp83ekfrhh09qg5'),
          [AddressChain.liquid]);
    });

    test('detects Liquid mainnet legacy confidential (VJL)', () {
      expect(detector.detect('VJLAaC6dE1aB6caa6sZ7n4cE'),
          [AddressChain.liquid]);
    });

    test('detects Liquid mainnet P2PKH (Q-prefix)', () {
      expect(detector.detect('QLFdUbou6t8h4ku6FQH4UKhDjE9NtJTKZ'),
          [AddressChain.liquid]);
    });

    test('detects Liquid mainnet P2SH (H-prefix)', () {
      expect(detector.detect('Hq3HRRVSKsdVRwWBKHYP3wNkHMZeUpJh'),
          [AddressChain.liquid]);
    });

    test('returns both chains for unknown / ambiguous prefix', () {
      expect(
        detector.detect('zzzunknownprefix123'),
        containsAll([AddressChain.bitcoin, AddressChain.liquid]),
      );
    });

    test('handles URI scheme via detect', () {
      expect(detector.detect('bitcoin:bc1qabc?amount=1'),
          [AddressChain.bitcoin]);
    });

    test('returns empty list for empty input', () {
      expect(detector.detect(''), isEmpty);
    });
  });
}
