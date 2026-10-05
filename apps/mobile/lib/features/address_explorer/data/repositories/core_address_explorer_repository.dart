import 'package:fpdart/fpdart.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/features/address_explorer/domain/entities/address_match.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_utxo.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_status.dart';
import 'package:mooze_mobile/features/address_explorer/domain/repositories/address_explorer_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/infra/core/core_dto_mapper.dart';

/// External indexes the old implementation walked to find a Bitcoin
/// derivation index or a UTXO address (`_kBitcoinNextUnusedScanCap`).
const int kCoreBitcoinIndexScanCap = 100;

/// Addresses per chain that the Liquid ownership probe scans
/// (`_kLiquidOwnershipScanLimit`).
const int kCoreLiquidOwnershipScanLimit = 200;

/// [AddressExplorerRepository] over mooze-core.
///
/// Reproduces the outputs of `AddressExplorerRepositoryImpl` with the core
/// calls instead of the BDK and LWK handles. The core wallets must be
/// connected; the Core* wallet services connect them at boot.
class CoreAddressExplorerRepository implements AddressExplorerRepository {
  CoreAddressExplorerRepository({required MoozeCore core}) : _core = core;

  final MoozeCore _core;

  // ────────────────────────────────────────────────────────────────────
  // Bitcoin
  // ────────────────────────────────────────────────────────────────────

  @override
  TaskEither<WalletError, List<WalletAddress>> listBitcoinAddresses({
    int limit = 100,
  }) {
    return _run(() async {
      final derived = await _core.bitcoinDerivedAddresses(
        keychain: KeychainDto.external_,
        start: 0,
        count: limit < 0 ? 0 : limit,
      );
      final utxos = await _core.bitcoinUnspentOutputs();
      return _rows(
        AddressChain.bitcoin,
        derived,
        utxos,
        keyOfAddress: (a) => a.scriptHex,
        keyOfUtxo: (u) => u.scriptHex,
      );
    });
  }

  @override
  TaskEither<WalletError, List<AddressUtxo>> listBitcoinUtxos() {
    return _run(() async {
      final utxos = await _core.bitcoinUnspentOutputs();
      return [
        for (final u in utxos)
          _utxo(
            AddressChain.bitcoin,
            // NOTE(core): the old implementation only knew the first 100
            // external addresses. Other outputs (change) got an empty
            // address. Kept as before.
            u.keychain == KeychainDto.external_ &&
                    u.index < kCoreBitcoinIndexScanCap
                ? u.address
                : '',
            u,
          ),
      ];
    });
  }

  @override
  TaskEither<WalletError, AddressMatch> isOwnedBitcoinAddress(String address) {
    return TaskEither(() async {
      try {
        final owned = await _core.bitcoinIsMine(address: address);
        if (owned == null) return Either.right(AddressMatch.notOwned(address));

        final derived = (await _core.bitcoinDerivedAddresses(
          keychain: owned.keychain,
          start: owned.index,
          count: 1,
        )).single;
        final utxos = (await _core.bitcoinUnspentOutputs())
            .where((u) => u.scriptHex == derived.scriptHex)
            .map((u) => _utxo(AddressChain.bitcoin, address, u))
            .toList();
        // The old implementation walked the first 100 external addresses
        // for the index. A change address stays owned without an index.
        final index =
            owned.keychain == KeychainDto.external_ &&
                owned.index < kCoreBitcoinIndexScanCap
            ? owned.index
            : null;
        return Either.right(
          AddressMatch.owned(
            address: address,
            chain: AddressChain.bitcoin,
            // As before, "used" comes from the history only, not the UTXOs.
            status: derived.used ? AddressStatus.used : AddressStatus.unused,
            derivationIndex: index,
            utxos: utxos,
          ),
        );
      } catch (_) {
        // A malformed or wrong-network address is "not owned", so the
        // multi-chain probe can fall back to Liquid.
        return Either.right(AddressMatch.notOwned(address));
      }
    });
  }

  @override
  TaskEither<WalletError, WalletAddress> getNextUnusedBitcoinAddress() {
    return _run(() async {
      // The core walks past used addresses, reveals up to the result and
      // persists, as `nextFreshReceiveAddress` did.
      final next = await _core.bitcoinNextUnusedAddress();
      return WalletAddress(
        address: next.address,
        chain: AddressChain.bitcoin,
        status: AddressStatus.unused,
        derivationIndex: next.index,
      );
    });
  }

  // ────────────────────────────────────────────────────────────────────
  // Liquid
  // ────────────────────────────────────────────────────────────────────

  @override
  TaskEither<WalletError, List<WalletAddress>> listLiquidAddresses({
    int limit = 100,
  }) {
    return _run(() async {
      final derived = await _core.liquidDerivedAddresses(
        keychain: KeychainDto.external_,
        start: 0,
        count: limit < 0 ? 0 : limit,
      );
      final utxos = await _core.liquidUnspentOutputs();
      return _rows(
        AddressChain.liquid,
        derived,
        utxos,
        keyOfAddress: (a) => a.unconfidential ?? a.address,
        keyOfUtxo: (u) => u.unconfidential ?? u.address,
      );
    });
  }

  @override
  TaskEither<WalletError, List<AddressUtxo>> listLiquidUtxos() {
    return _run(() async {
      final utxos = await _core.liquidUnspentOutputs();
      return [for (final u in utxos) _utxo(AddressChain.liquid, u.address, u)];
    });
  }

  @override
  TaskEither<WalletError, AddressMatch> isOwnedLiquidAddress(String address) {
    return TaskEither(() async {
      try {
        final owned = await _core.liquidIsMine(
          address: address,
          scanLimit: kCoreLiquidOwnershipScanLimit,
        );
        // NOTE(core): the core also finds change addresses. The old
        // implementation scanned the external chain only, so a change
        // address stays "not owned" here.
        if (owned == null || owned.keychain != KeychainDto.external_) {
          return Either.right(AddressMatch.notOwned(address));
        }
        final derived = (await _core.liquidDerivedAddresses(
          keychain: KeychainDto.external_,
          start: owned.index,
          count: 1,
        )).single;
        final standard = derived.unconfidential ?? derived.address;
        final utxos = (await _core.liquidUnspentOutputs())
            .where((u) => (u.unconfidential ?? u.address) == standard)
            .map((u) => _utxo(AddressChain.liquid, address, u))
            .toList();
        final used = utxos.isNotEmpty || derived.used;
        return Either.right(
          AddressMatch.owned(
            address: address,
            chain: AddressChain.liquid,
            status: used ? AddressStatus.used : AddressStatus.unused,
            derivationIndex: owned.index,
            utxos: utxos,
          ),
        );
      } catch (_) {
        // Any validation or core error is "not owned", as before.
        return Either.right(AddressMatch.notOwned(address));
      }
    });
  }

  @override
  TaskEither<WalletError, WalletAddress> getNextUnusedLiquidAddress() {
    return _run(() async {
      // LWK's last unused address plus a history check. Reveals nothing.
      final next = await _core.liquidNextUnusedAddress();
      return WalletAddress(
        address: next.address,
        chain: AddressChain.liquid,
        status: next.used ? AddressStatus.used : AddressStatus.unused,
        derivationIndex: next.index,
      );
    });
  }

  // ────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────

  TaskEither<WalletError, T> _run<T>(Future<T> Function() body) {
    return TaskEither.tryCatch(
      body,
      (err, _) => WalletError(
        WalletErrorType.sdkError,
        err is CoreError ? coreErrorMessage(err) : err.toString(),
      ),
    );
  }

  /// Groups [utxos] under the [derived] addresses that own them.
  ///
  /// An address is used if it holds a UTXO or the core reports history
  /// for it. `receivedSats` is the sum of the current UTXOs, as before.
  List<WalletAddress> _rows(
    AddressChain chain,
    List<DerivedAddressDto> derived,
    List<WalletUtxoDto> utxos, {
    required String Function(DerivedAddressDto) keyOfAddress,
    required String Function(WalletUtxoDto) keyOfUtxo,
  }) {
    final byKey = <String, List<WalletUtxoDto>>{};
    for (final u in utxos) {
      byKey.putIfAbsent(keyOfUtxo(u), () => []).add(u);
    }
    final rows = <WalletAddress>[
      for (final a in derived)
        () {
          final us = (byKey[keyOfAddress(a)] ?? const <WalletUtxoDto>[])
              .map((u) => _utxo(chain, a.address, u))
              .toList();
          return WalletAddress(
            address: a.address,
            chain: chain,
            status: us.isNotEmpty || a.used
                ? AddressStatus.used
                : AddressStatus.unused,
            derivationIndex: a.index,
            receivedSats: us.fold<BigInt>(BigInt.zero, (s, u) => s + u.value),
            utxos: us,
          );
        }(),
    ];
    rows.sort((a, b) => a.derivationIndex.compareTo(b.derivationIndex));
    return rows;
  }

  AddressUtxo _utxo(AddressChain chain, String address, WalletUtxoDto u) {
    return AddressUtxo(
      address: address,
      chain: chain,
      outpoint: '${u.txid}:${u.vout}',
      value: u.amountSat,
      assetId: u.assetId,
      // NOTE(core): the old implementation reported every UTXO as
      // confirmed. Kept; `u.confirmationHeight` holds the real state.
      confirmed: true,
    );
  }
}
