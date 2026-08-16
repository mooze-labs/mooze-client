@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lwk/lwk.dart' as lwk;

import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/wallet_credentials.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/domain/repositories/wallet_directory_guard.dart';
import 'package:mooze_mobile/infra/lwk/liquid_wallet_service_impl.dart';
import 'package:mooze_mobile/shared/clock/clock.dart';
import 'package:mooze_mobile/shared/logging/structured_logger.dart';

/// Real-FFI coverage for the Phase 1 send path, **without funds**.
///
/// The funded round trip lives in `liquid_send_roundtrip_test.dart` and needs
/// a wallet with L-BTC. This suite covers everything that does not: that the
/// vendored bindings load, that `connect`/`sync`/`addressLastUnused`/`utxos`
/// work against real testnet Electrum, and that `buildLbtcSend` and
/// `signAndBroadcastPset` reach LWK and map its errors instead of throwing.
///
/// It uses a throwaway mnemonic that is expected to hold nothing. Never fund
/// it — it is published in this file.
///
/// Requires the native library at `build/unit_test_assets/liblwk.dylib`
/// (macOS) or `.so` (Linux). Build it with:
///
///   cd packages/lwk-dart/rust && cargo build --release
///   cp target/release/liblwk.dylib ../../../build/unit_test_assets/
///
/// Skips itself when the library is absent, so CI stays green without it.
const _throwawayMnemonic =
    'abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon about';

const _electrumTestnet = 'blockstream.info:465';

String get _dylibPath {
  final base = '${Directory.current.path}/build/unit_test_assets';
  return Platform.isMacOS ? '$base/liblwk.dylib' : '$base/liblwk.so';
}

bool get _hasDylib => File(_dylibPath).existsSync();

/// Opt-in even when the dylib is present.
///
/// Each test here runs a real Electrum sync (~20 s) against Liquid testnet.
/// Left on by default it makes every `flutter test` run minutes longer and
/// flaky under parallel load — the suite passes in isolation but times out
/// when scheduled alongside 400 other tests. Enable with
/// `--dart-define=LWK_FFI_TESTS=1`.
const _optIn = bool.fromEnvironment('LWK_FFI_TESTS');

void main() {
  final skipReason =
      !_optIn
          ? 'Opt-in: pass --dart-define=LWK_FFI_TESTS=1 (needs the native LWK '
              'library and network). See this file\'s header.'
          : _hasDylib
          ? null
          : 'Native LWK library not built. See this file\'s header.';

  group('LWK send path against real FFI', () {
    late LiquidWalletServiceImpl service;
    late _TempDirGuard guard;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      if (!_optIn || !_hasDylib) return;
      await lwk.LibLwk.init();
    });

    setUp(() {
      guard = _TempDirGuard();
      service = LiquidWalletServiceImpl(
        directoryGuard: guard,
        logger: ConsoleStructuredLogger(minLevel: LogLevel.warn),
        clock: const SystemClock(),
        electrumUrl: _electrumTestnet,
        validateDomain: true,
      );
    });

    tearDown(() async {
      await service.disconnect();
      guard.cleanUp();
    });

    Future<void> connect() async {
      final r = await service.connect(
        const WalletCredentials(
          mnemonic: _throwawayMnemonic,
          network: AppNetwork.testnet,
        ),
      );
      expect(r.isRight(), isTrue, reason: 'connect: ${_msg(r)}');
    }

    test('connect derives a descriptor and opens the wallet', () async {
      await connect();
      expect(service.currentState.isOperational, isTrue);
      expect(service.sdkClient, isNotNull);
    }, skip: skipReason);

    test(
      'sync reaches testnet Electrum and yields an address + UTXO set',
      () async {
        await connect();

        final synced = await service.sync(timeout: const Duration(seconds: 60));
        expect(synced.isRight(), isTrue, reason: 'sync: ${_msg(synced)}');

        final address = await service.getReceiveAddress();
        expect(address.isRight(), isTrue, reason: 'address: ${_msg(address)}');
        final addr = address.getOrElse((_) => '');
        // Testnet confidential addresses are `tlq1…`; mainnet would be `lq1…`.
        // Getting this wrong would silently send peg-in proceeds to the wrong
        // network, so assert the prefix rather than just non-emptiness.
        expect(
          addr,
          startsWith('tlq1'),
          reason: 'expected a testnet confidential address, got "$addr"',
        );

        final utxos = await service.getUtxos();
        expect(utxos.isRight(), isTrue, reason: 'utxos: ${_msg(utxos)}');
      },
      skip: skipReason,
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test(
      'buildLbtcSend maps insufficient funds to a Left, not a throw',
      () async {
        await connect();
        await service.sync(timeout: const Duration(seconds: 60));

        final address = await service.getReceiveAddress();
        final self = address.getOrElse((_) => '');

        // 21M BTC in sats — unspendable on any wallet, so coin selection is
        // guaranteed to fail regardless of what this shared testnet vector
        // happens to hold at the time. (It does hold funds: it is a public
        // test mnemonic that many projects fund. Asserting "empty wallet"
        // here would be a test that passes only by accident.)
        final draft = await service.buildLbtcSend(
          destination: self,
          amountSat: BigInt.from(2100000000000000),
        );

        expect(
          draft.isLeft(),
          isTrue,
          reason: 'coin selection cannot cover 21M BTC',
        );
        expect(_msg(draft), contains('buildLbtcSend failed'));
      },
      skip: skipReason,
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test(
      'buildLbtcSend produces a decodable draft when funds are available',
      () async {
        // Proves steps 3-5 of the Phase 1 gate against real LWK: UTXO
        // selection, PSET construction, and fee read-back. Skipped rather
        // than failed when the shared testnet vector happens to be drained.
        await connect();
        await service.sync(timeout: const Duration(seconds: 60));

        final address = await service.getReceiveAddress();
        final self = address.getOrElse((_) => '');

        final draft = await service.buildLbtcSend(
          destination: self,
          amountSat: BigInt.from(1000),
        );

        if (draft.isLeft()) {
          markTestSkipped(
            'shared testnet vector has no spendable L-BTC: '
            '${_msg(draft)}',
          );
          return;
        }

        final d = draft.getOrElse((_) => throw StateError('unreachable'));
        expect(d.pset, isNotEmpty);
        expect(d.amountSat, BigInt.from(1000));
        expect(
          d.feeSat,
          greaterThan(BigInt.zero),
          reason: 'decodeTx must read a real fee back out of the PSET',
        );
        expect(d.totalSat, d.amountSat + d.feeSat);
        // Liquid minimum relay, since we passed no explicit rate.
        expect(d.feeRateSatPerKvb, 100.0);
      },
      skip: skipReason,
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test(
      'buildLbtcSend rejects a malformed destination at build time',
      () async {
        await connect();

        final draft = await service.buildLbtcSend(
          destination: 'definitely-not-an-address',
          amountSat: BigInt.from(1000),
        );

        expect(draft.isLeft(), isTrue);
        expect(_msg(draft), contains('buildLbtcSend failed'));
      },
      skip: skipReason,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'signAndBroadcastPset maps a malformed PSET to a Left, not a throw',
      () async {
        await connect();

        final result = await service.signAndBroadcastPset(
          pset: 'this-is-not-a-pset',
          mnemonic: _throwawayMnemonic,
        );

        expect(result.isLeft(), isTrue);
        // Must fail in signTx, never reaching the network.
        expect(_msg(result), contains('signTx failed'));
      },
      skip: skipReason,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

String _msg<L extends Failure, R>(Either<L, R> e) =>
    e.match((l) => l.message, (_) => '<right>');

class _TempDirGuard implements WalletDirectoryGuard {
  final Map<String, Directory> _dirs = {};

  @override
  Future<Either<StorageFailure, String>> acquire(String relativePath) async {
    final dir = _dirs.putIfAbsent(
      relativePath,
      () => Directory.systemTemp.createTempSync('lwk-ffi-'),
    );
    return Right(dir.path);
  }

  @override
  Future<void> release(String relativePath) async {}

  @override
  Future<Either<StorageFailure, Unit>> wipe(String relativePath) async {
    _dirs.remove(relativePath)?.deleteSync(recursive: true);
    return const Right(unit);
  }

  void cleanUp() {
    for (final dir in _dirs.values) {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
    _dirs.clear();
  }
}
