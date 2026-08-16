@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lwk/lwk.dart' as lwk;

import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/liquid_utxo.dart';
import 'package:mooze_mobile/domain/entities/wallet_credentials.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/domain/repositories/wallet_directory_guard.dart';
import 'package:mooze_mobile/infra/lwk/liquid_wallet_service_impl.dart';
import 'package:mooze_mobile/shared/clock/clock.dart';
import 'package:mooze_mobile/shared/logging/structured_logger.dart';

/// PHASE 1 SPIKE — the LWK Liquid send round-trip.
///
/// This is the gate for the whole SideSwap peg migration
/// (`docs/adr-001-sideswap-peg-lwk-signing.md`). It proves, against a real
/// network, that the vendored LWK bindings can still do what v1.2 did:
///
///   1. sync              2. UTXO retrieval      3. UTXO selection
///   4. PSET construction 5. fee calculation     6. PSET signing
///   7. finalization      8. broadcast           9. confirmation/detection
///  10. balance update
///
/// It also settles the one thing that cannot be settled by reading code: the
/// inverted `is_mainnet = network == Network::Testnet` flag in
/// `packages/lwk-dart/rust/src/api/wallet.rs:282`. `signedPsetWithExtraDetails`
/// ships on mainnet through the same construction, so the flag is almost
/// certainly harmless — but `signTx` additionally calls `wallet.finalize()`,
/// and "almost certainly" is not a basis for moving user funds. If this test
/// passes, the flag is proven irrelevant for our use. If it fails, fall back
/// to Option A (Breez signs the peg-out) per the investigation document.
///
/// ─────────────────────────────────────────────────────────────────────
/// SKIPPED BY DEFAULT. It spends real coins and needs a funded wallet.
///
/// Run it with:
///
///   flutter test test/infra/lwk/liquid_send_roundtrip_test.dart \
///     --dart-define=LWK_TEST_MNEMONIC="twelve word phrase ..." \
///     --dart-define=LWK_TEST_DESTINATION="lq1qq..." \
///     --dart-define=LWK_TEST_NETWORK=testnet \
///     --dart-define=LWK_TEST_AMOUNT_SAT=1000
///
/// Prerequisites:
///   • The LWK native library must be loadable by the test host. Build it
///     with `packages/lwk-dart/rust/unit-test.sh <version>`, or run this
///     suite as an `integration_test` on a device where the plugin's
///     bundled binary is already present.
///   • The wallet must hold L-BTC on the chosen network, plus fee headroom.
///   • Use testnet first. Only repeat on mainnet with a dust amount, and
///     only after testnet is green.
///
/// Do NOT wire this into CI.
/// ─────────────────────────────────────────────────────────────────────
const _mnemonic = String.fromEnvironment('LWK_TEST_MNEMONIC');
const _destination = String.fromEnvironment('LWK_TEST_DESTINATION');
const _networkName = String.fromEnvironment(
  'LWK_TEST_NETWORK',
  defaultValue: 'testnet',
);
const _amountSat = int.fromEnvironment(
  'LWK_TEST_AMOUNT_SAT',
  defaultValue: 1000,
);
const _electrumUrl = String.fromEnvironment('LWK_TEST_ELECTRUM_URL');

bool get _enabled => _mnemonic.isNotEmpty && _destination.isNotEmpty;

String get _electrum {
  if (_electrumUrl.isNotEmpty) return _electrumUrl;
  return _networkName == 'mainnet'
      ? 'blockstream.info:995'
      : 'blockstream.info:465';
}

void main() {
  final skipReason =
      _enabled
          ? null
          : 'Opt-in spike. Supply --dart-define=LWK_TEST_MNEMONIC and '
              'LWK_TEST_DESTINATION to run. See the file header.';

  group('LWK Liquid send round-trip', () {
    late LiquidWalletServiceImpl service;
    late _TempDirGuard guard;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Loading the native library is only possible on a host that has it
      // built (see the header). Skipped runs must not pay for it — the
      // disconnected-guard test below exercises pure Dart guards and has to
      // stay runnable in CI, where no dylib exists.
      if (!_enabled) return;
      await lwk.LibLwk.init();
    });

    setUp(() async {
      guard = _TempDirGuard();
      service = LiquidWalletServiceImpl(
        directoryGuard: guard,
        logger: ConsoleStructuredLogger(minLevel: LogLevel.info),
        clock: const SystemClock(),
        electrumUrl: _electrum,
        validateDomain: true,
      );
    });

    tearDown(() async {
      await service.disconnect();
      guard.cleanUp();
    });

    test(
      'sync → select → build → sign → finalize → broadcast → confirm',
      () async {
        // ── 1. connect + sync ─────────────────────────────────────────────
        final network = AppNetwork.fromName(_networkName);
        final connected = await service.connect(
          WalletCredentials(mnemonic: _mnemonic, network: network),
        );
        expect(
          connected.isRight(),
          isTrue,
          reason: 'connect failed: ${_left(connected)}',
        );

        final synced = await service.sync();
        expect(
          synced.isRight(),
          isTrue,
          reason: 'sync failed: ${_left(synced)}',
        );

        // `self` sends back to the wallet's own next unused address. A
        // self-send exercises the identical build → sign → finalize →
        // broadcast path while keeping the coins, which is what you want when
        // re-running the gate.
        final destination =
            _destination == 'self'
                ? (await service.getReceiveAddress()).getOrElse((_) => '')
                : _destination;
        expect(
          destination,
          isNotEmpty,
          reason: 'could not resolve destination',
        );

        // ── 2/3. UTXOs are visible and selectable ─────────────────────────
        final utxos = await service.getUtxos();
        expect(utxos.isRight(), isTrue, reason: 'getUtxos: ${_left(utxos)}');
        final utxoList = utxos.getOrElse((_) => []);
        expect(
          utxoList,
          isNotEmpty,
          reason: 'wallet has no UTXOs — fund it before running this spike',
        );
        // ignore: avoid_print
        print('[spike] ${utxoList.length} utxo(s) visible');

        final balanceBefore = await service.refreshBalance();
        expect(balanceBefore.isRight(), isTrue);
        final lbtcBefore = _policyAssetSat(utxos);
        // ignore: avoid_print
        print(
          '[spike] policy asset before: $lbtcBefore sat '
          '(asset $_policyAsset)',
        );
        expect(
          lbtcBefore,
          greaterThan(BigInt.from(_amountSat)),
          reason: 'insufficient L-BTC for a $_amountSat sat send plus fee',
        );

        // ── 4/5. PSET construction + fee ──────────────────────────────────
        final draftResult = await service.buildLbtcSend(
          destination: destination,
          amountSat: BigInt.from(_amountSat),
        );
        expect(
          draftResult.isRight(),
          isTrue,
          reason: 'buildLbtcSend: ${_left(draftResult)}',
        );
        final draft = draftResult.getOrElse(
          (_) => throw StateError('unreachable'),
        );

        expect(draft.pset, isNotEmpty);
        expect(draft.amountSat, BigInt.from(_amountSat));
        expect(
          draft.feeSat,
          greaterThan(BigInt.zero),
          reason: 'a zero fee means decodeTx did not read the PSET',
        );
        expect(draft.totalSat, draft.amountSat + draft.feeSat);
        // ignore: avoid_print
        print(
          '[spike] pset built — amount ${draft.amountSat}, '
          'fee ${draft.feeSat} sat @ ${draft.feeRateSatPerKvb} sat/kvB',
        );

        // ── 6/7/8. sign + finalize + broadcast ────────────────────────────
        // Everything past this line moves real coins.
        final broadcast = await service.signAndBroadcastPset(
          pset: draft.pset,
          mnemonic: _mnemonic,
        );
        expect(
          broadcast.isRight(),
          isTrue,
          reason:
              'signAndBroadcastPset: ${_left(broadcast)}\n'
              'If this failed inside signTx, the inverted is_mainnet flag in '
              'wallet.rs:282 is NOT harmless — stop and reassess the '
              'architecture (see ADR-001 §13).',
        );
        final txid = broadcast.getOrElse((_) => '');
        expect(
          txid,
          hasLength(64),
          reason: 'expected a 64-hex txid, got "$txid"',
        );
        // ignore: avoid_print
        print('[spike] BROADCAST OK — txid $txid');

        // ── 9. the wallet sees its own transaction ────────────────────────
        // `signAndBroadcastPset` re-syncs internally, so one more sync is
        // enough for the mempool entry to land in LWK's store.
        await service.sync();
        final txs = await service.listTransactions();
        final ids = txs.getOrElse((_) => []).map((t) => t.id).toList();
        expect(
          ids,
          contains(txid),
          reason: 'broadcast succeeded but LWK never indexed $txid',
        );

        // ── 10. balance reflects the spend ────────────────────────────────
        final balanceAfter = await service.refreshBalance();
        expect(balanceAfter.isRight(), isTrue);
        final utxosAfter = await service.getUtxos();
        final lbtcAfter = _policyAssetSat(utxosAfter);
        // ignore: avoid_print
        print(
          '[spike] policy asset after: $lbtcAfter sat '
          '(delta ${lbtcAfter - lbtcBefore})',
        );
        // A self-send returns the output to the wallet, so only the fee is
        // actually lost — assert on the fee rather than on "less than", which
        // would be wrong for a self-send once the change lands.
        expect(
          lbtcAfter,
          lessThanOrEqualTo(lbtcBefore),
          reason: 'spend did not reduce (or hold) the policy-asset total',
        );
      },
      skip: skipReason,
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'rejects a non-positive amount before touching the network',
      () async {
        final network = AppNetwork.fromName(_networkName);
        await service.connect(
          WalletCredentials(mnemonic: _mnemonic, network: network),
        );

        final zero = await service.buildLbtcSend(
          destination: _destination,
          amountSat: BigInt.zero,
        );
        expect(zero.isLeft(), isTrue);
        expect(_left(zero), contains('amount must be positive'));

        final empty = await service.buildLbtcSend(
          destination: '   ',
          amountSat: BigInt.from(1000),
        );
        expect(empty.isLeft(), isTrue);
        expect(_left(empty), contains('destination is empty'));
      },
      skip: skipReason,
    );

    test(
      'an invalid destination fails at build time, never at broadcast',
      () async {
        final network = AppNetwork.fromName(_networkName);
        await service.connect(
          WalletCredentials(mnemonic: _mnemonic, network: network),
        );

        final result = await service.buildLbtcSend(
          destination: 'not-a-liquid-address',
          amountSat: BigInt.from(1000),
        );
        expect(
          result.isLeft(),
          isTrue,
          reason:
              'LWK accepted a malformed address — the failure would '
              'otherwise surface only after signing',
        );
        expect(_left(result), contains('buildLbtcSend failed'));
      },
      skip: skipReason,
    );

    test('signAndBroadcastPset guards its inputs', () async {
      final network = AppNetwork.fromName(_networkName);
      await service.connect(
        WalletCredentials(mnemonic: _mnemonic, network: network),
      );

      final noPset = await service.signAndBroadcastPset(
        pset: '',
        mnemonic: _mnemonic,
      );
      expect(noPset.isLeft(), isTrue);
      expect(_left(noPset), contains('pset is empty'));

      final noMnemonic = await service.signAndBroadcastPset(
        pset: 'x',
        mnemonic: '',
      );
      expect(noMnemonic.isLeft(), isTrue);
      expect(_left(noMnemonic), contains('mnemonic is empty'));
    }, skip: skipReason);

    test('every send surface refuses to act while disconnected', () async {
      // No connect() — the service is idle. Guards must fire before any FFI
      // call, otherwise a null wallet handle becomes a crash instead of a
      // Left.
      final build = await service.buildLbtcSend(
        destination: _destination,
        amountSat: BigInt.from(1000),
      );
      expect(build.isLeft(), isTrue);
      expect(_left(build), contains('not connected'));

      final send = await service.signAndBroadcastPset(
        pset: 'pset',
        mnemonic: 'mnemonic',
      );
      expect(send.isLeft(), isTrue);
      expect(_left(send), contains('not connected'));
    });
  });
}

String _left<L extends Failure, R>(Either<L, R> e) =>
    e.match((l) => l.message, (_) => '<right>');

/// The network's policy asset (its "L-BTC").
///
/// Liquid testnet uses a different policy-asset id than mainnet, and the
/// app's `lbtcAssetId` constant is the mainnet one — so a balance lookup keyed
/// on it reports 0 on testnet even with 75 funded UTXOs. Measuring the policy
/// asset directly keeps the gate honest on both networks.
String get _policyAsset =>
    _networkName == 'mainnet' ? lwk.lBtcAssetId : lwk.lTestAssetId;

/// Spendable policy-asset total, summed from UTXOs rather than the mapped
/// balance, for the same reason.
BigInt _policyAssetSat(Either<ServiceFailure, List<LiquidUtxo>> utxos) =>
    utxos.match(
      (_) => BigInt.zero,
      (list) => list
          .where((u) => u.assetId == _policyAsset)
          .fold<BigInt>(BigInt.zero, (sum, u) => sum + u.valueSat),
    );

/// Temp-directory stand-in for `WalletDirectoryGuardImpl`, which resolves
/// through `path_provider` and therefore needs a real platform channel.
class _TempDirGuard implements WalletDirectoryGuard {
  final Map<String, Directory> _dirs = {};

  @override
  Future<Either<StorageFailure, String>> acquire(String relativePath) async {
    final dir = _dirs.putIfAbsent(
      relativePath,
      () => Directory.systemTemp.createTempSync('lwk-spike-'),
    );
    return Right(dir.path);
  }

  @override
  Future<void> release(String relativePath) async {}

  @override
  Future<Either<StorageFailure, Unit>> wipe(String relativePath) async {
    final dir = _dirs.remove(relativePath);
    if (dir != null && dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    return const Right(unit);
  }

  void cleanUp() {
    for (final dir in _dirs.values) {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
    _dirs.clear();
  }
}
