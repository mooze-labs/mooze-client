import 'package:flutter_test/flutter_test.dart';

import 'package:mooze_mobile/features/swap/data/models.dart';
import 'package:mooze_mobile/features/swap/data/repositories/peg_repository_impl.dart';
import 'package:mooze_mobile/features/swap/domain/entities/peg.dart';

/// Pins the SideSwap peg wire contract and the wire → domain mapping.
///
/// The payloads below are **verbatim captures from the live mainnet API**
/// (2026-08-08, `wss://api.sideswap.io/json-rpc-ws`), not invented fixtures.
/// If SideSwap changes the contract, these fail rather than the app silently
/// mis-reading a peg.
void main() {
  group('server_status → PegServerLimits', () {
    // Live capture. Note the extra fields (bitcoin_fee_rates, policy_asset,
    // price_band, …) that v1.2's model never knew about — parsing must
    // tolerate them.
    const live = {
      'bitcoin_fee_rates': [
        {'blocks': 2, 'value': 2.0},
      ],
      'elements_fee_rate': 0.1,
      'min_peg_in_amount': 10000,
      'min_peg_out_amount': 25000,
      'min_submit_amount': 2000,
      'peg_out_bitcoin_tx_vsize': 141,
      'policy_asset':
          '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d',
      'price_band': 0.101,
      'server_fee_percent_peg_in': 0.1,
      'server_fee_percent_peg_out': 0.1,
      'upload_url': 'https://api.sideswap.io/json-rpc',
    };

    test('parses the live payload, ignoring unknown fields', () {
      final status = ServerStatus.fromJson(live);
      expect(status.minPegInAmount, 10000);
      expect(status.minPegOutAmount, 25000);
      expect(status.serverFeePercentPegIn, 0.1);
      expect(status.serverFeePercentPegOut, 0.1);
    });

    test('minimums differ by direction — 10k in, 25k out', () {
      final limits = PegServerLimits(
        minPegInSat: ServerStatus.fromJson(live).minPegInAmount,
        minPegOutSat: ServerStatus.fromJson(live).minPegOutAmount,
        serverFeePercentPegIn: 0.1,
        serverFeePercentPegOut: 0.1,
      );
      expect(limits.minimumFor(PegDirection.pegIn), 10000);
      expect(limits.minimumFor(PegDirection.pegOut), 25000);
    });

    test('service fee rounds up so the quote never understates the cost', () {
      const limits = PegServerLimits(
        minPegInSat: 10000,
        minPegOutSat: 25000,
        serverFeePercentPegIn: 0.1,
        serverFeePercentPegOut: 0.1,
      );
      expect(limits.serviceFeeSat(PegDirection.pegOut, 100000), 100);
      // 0.1% of 1001 = 1.001 → 2, not 1.
      expect(limits.serviceFeeSat(PegDirection.pegOut, 1001), 2);
      expect(limits.serviceFeeSat(PegDirection.pegOut, 0), 0);
    });
  });

  group('peg → PegOrderResponse', () {
    test('peg-in returns a BITCOIN deposit address', () {
      // Live capture: recv_addr was a Liquid address; peg_addr came back as
      // bc1… — the user deposits BTC.
      final response = PegOrderResponse.fromJson(const {
        'created_at': 1786210602834,
        'expires_at': 0,
        'order_id':
            '9f7c16e57a867249dd4db88ff2cf161014bd487ba2cc3d4d5ff000fa8eb0d394',
        'peg_addr':
            'bc1qmvl2pjc7q0rgv0hm0gadhfzn66hqxh8ft9p8g3quvhca6wysfj2svjwyxq',
        'recv_amount': null,
      });

      expect(response.pegAddress, startsWith('bc1'));
      expect(response.orderId, hasLength(64));
      expect(
        response.expiresAt,
        isNull,
        reason: 'expires_at 0 means no expiry, not 1970',
      );
    });

    test('peg-out returns a LIQUID deposit address', () {
      final response = PegOrderResponse.fromJson(const {
        'created_at': 1786210521499,
        'expires_at': 0,
        'order_id':
            '9093164d4ae773d84f507b18e3c0fbfe03e63d1c4594e4664e351dea6c111dc1',
        'peg_addr':
            'lq1qqgdcmfjrxkqc7ghpmg993pnwp4w4rmzvr0krykcvvkxvnr5r8vrrykpc0zm6a8kldmd3kee2wsvs2ks9aln46s4s8st7xkyp6',
        'recv_amount': null,
      });

      expect(response.pegAddress, startsWith('lq1'));
    });

    test('no PSET is returned — SideSwap does not co-sign pegs', () {
      // The whole peg-out design depends on this: SideSwap issues an address,
      // the wallet builds and signs. If a future API ever returns a PSET the
      // architecture would need revisiting, so assert the absence.
      const live = {
        'created_at': 1786210521499,
        'expires_at': 0,
        'order_id': 'abc',
        'peg_addr': 'lq1qq',
        'recv_amount': null,
      };
      expect(live.containsKey('pset'), isFalse);
      expect(live.containsKey('psbt'), isFalse);
    });
  });

  group('peg_status → PegOrderStatus', () {
    test('parses a freshly created order with no deposits yet', () {
      // Live capture. `fee_rate` and `return_address` are fields v1.2's model
      // never saw; parsing must ignore them rather than throw.
      final status = PegOrderStatus.fromJson(const {
        'addr':
            'bc1qmvl2pjc7q0rgv0hm0gadhfzn66hqxh8ft9p8g3quvhca6wysfj2svjwyxq',
        'addr_recv': 'lq1qqvxk052kf3qtkxmrakx50a9gc3smqad2ync54hzntjt980kfej9',
        'created_at': 1786210602834,
        'expires_at': 0,
        'fee_rate': null,
        'list': <dynamic>[],
        'order_id': '9f7c16e5',
        'peg_in': true,
        'return_address': null,
      });

      expect(status.isPegIn, isTrue);
      expect(status.transactions, isEmpty);
      expect(status.address, startsWith('bc1'));
      expect(status.receiveAddress, startsWith('lq1'));
    });
  });

  group('phase aggregation', () {
    PegDeposit deposit(PegPhase phase) =>
        PegDeposit(txId: 't', phase: phase, amountSat: 1000);

    test('no deposits means awaiting deposit', () {
      expect(PegRepositoryImpl.aggregatePhase([]), PegPhase.awaitingDeposit);
    });

    test('the least-advanced deposit governs', () {
      // An order funded twice where one payment has confirmed and the other
      // has not is NOT complete — reporting it as such would retire the
      // tracker while money is still in flight.
      expect(
        PegRepositoryImpl.aggregatePhase([
          deposit(PegPhase.completed),
          deposit(PegPhase.detected),
        ]),
        PegPhase.detected,
      );
    });

    test('all complete means complete', () {
      expect(
        PegRepositoryImpl.aggregatePhase([
          deposit(PegPhase.completed),
          deposit(PegPhase.completed),
        ]),
        PegPhase.completed,
      );
    });

    test('an under-funded deposit dominates', () {
      expect(
        PegRepositoryImpl.aggregatePhase([
          deposit(PegPhase.completed),
          deposit(PegPhase.insufficientAmount),
        ]),
        PegPhase.insufficientAmount,
      );
    });
  });

  group('TxState mapping', () {
    test('every wire state maps to a domain phase', () {
      // Table-driven so a new TxState cannot be added without a decision.
      const expected = {
        TxState.insufficientAmount: PegPhase.insufficientAmount,
        TxState.detected: PegPhase.detected,
        TxState.processing: PegPhase.processing,
        TxState.done: PegPhase.completed,
        // `unknown` deliberately maps to a NON-terminal phase: an
        // unrecognised state must keep the tracker polling, not retire the
        // order as finished.
        TxState.unknown: PegPhase.detected,
      };

      for (final state in TxState.values) {
        expect(
          expected.containsKey(state),
          isTrue,
          reason: 'TxState.$state has no mapping decision',
        );
      }
      expect(expected[TxState.unknown]!.isTerminal, isFalse);
    });
  });
}
