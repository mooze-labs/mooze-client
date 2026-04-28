import 'package:bdk_flutter/bdk_flutter.dart' as bdk;
import 'package:fpdart/fpdart.dart';
import 'package:lwk/lwk.dart' as lwk;
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_match.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_utxo.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_status.dart';
import 'package:mooze_mobile/features/address_explorer/domain/repositories/address_explorer_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/shared/infra/bdk/wallet.dart';
import 'package:mooze_mobile/shared/infra/lwk/wallet.dart';

/// Hard cap when searching for the next unused address. Prevents runaway
/// loops if every derived index in the scan window has on-chain history.
const int _kBitcoinNextUnusedScanCap = 100;
const int _kLiquidOwnershipScanLimit = 200;

class AddressExplorerRepositoryImpl implements AddressExplorerRepository {
  final BdkDataSource _bdk;
  final LiquidDataSource _lwk;

  AddressExplorerRepositoryImpl({
    required BdkDataSource bdk,
    required LiquidDataSource lwk,
  })  : _bdk = bdk,
        _lwk = lwk;

  // ────────────────────────────────────────────────────────────────────
  // Bitcoin
  // ────────────────────────────────────────────────────────────────────

  @override
  TaskEither<WalletError, List<WalletAddress>> listBitcoinAddresses({
    int limit = 100,
  }) {
    return TaskEither.tryCatch(
      () async => _scanBitcoinAddresses(limit),
      (err, _) => WalletError(WalletErrorType.sdkError, err.toString()),
    );
  }

  @override
  TaskEither<WalletError, List<AddressUtxo>> listBitcoinUtxos() {
    return TaskEither.tryCatch(
      () async {
        final utxos = _bdk.wallet.listUnspent();
        // Map each UTXO back to the wallet-derived address that owns it by
        // comparing scripts against derived addresses up to a reasonable cap.
        final byScript = await _deriveBitcoinScriptMap(_kBitcoinNextUnusedScanCap);
        return utxos.where((u) => !u.isSpent).map((u) {
          final hex = _hex(u.txout.scriptPubkey.bytes);
          final entry = byScript[hex];
          return AddressUtxo(
            address: entry?.address ?? '',
            chain: AddressChain.bitcoin,
            outpoint: '${u.outpoint.txid}:${u.outpoint.vout}',
            value: u.txout.value,
            confirmed: true,
          );
        }).toList();
      },
      (err, _) => WalletError(WalletErrorType.sdkError, err.toString()),
    );
  }

  @override
  TaskEither<WalletError, AddressMatch> isOwnedBitcoinAddress(String address) {
    return TaskEither(() async {
      try {
        final parsed = await bdk.Address.fromString(
          s: address,
          network: _bdk.wallet.network(),
        );
        final script = parsed.scriptPubkey();
        final isMine = _bdk.wallet.isMine(script: script);
        if (!isMine) return Either.right(AddressMatch.notOwned(address));

        // Identify the derivation index by walking the descriptor.
        final scriptHex = _hex(script.bytes);
        int? foundIndex;
        for (int i = 0; i < _kBitcoinNextUnusedScanCap; i++) {
          final info = _bdk.wallet
              .getAddress(addressIndex: bdk.AddressIndex.peek(index: i));
          final derivedHex = _hex(info.address.scriptPubkey().bytes);
          if (derivedHex == scriptHex) {
            foundIndex = i;
            break;
          }
        }

        final used = await _bitcoinAddressIsUsed(scriptHex);
        final utxoCount = _bdk.wallet
            .listUnspent()
            .where((u) => !u.isSpent &&
                _hex(u.txout.scriptPubkey.bytes) == scriptHex)
            .length;
        return Either.right(
          AddressMatch.owned(
            address: address,
            chain: AddressChain.bitcoin,
            status: used ? AddressStatus.used : AddressStatus.unused,
            derivationIndex: foundIndex,
            utxoCount: utxoCount,
          ),
        );
      } catch (e) {
        // fromString throws for malformed or wrong-network addresses.
        // For a multi-chain probe we want to treat this as "not owned"
        // rather than a hard failure, so the orchestrator can fall back
        // to the Liquid probe.
        return Either.right(AddressMatch.notOwned(address));
      }
    });
  }

  @override
  TaskEither<WalletError, WalletAddress> getNextUnusedBitcoinAddress() {
    return TaskEither.tryCatch(
      () async {
        final usedScripts = _buildBitcoinUsedScriptSet();

        // Start from BDK's current "lastUnused" view and walk forward
        // until we find one with no on-chain history.
        final last = _bdk.wallet
            .getAddress(addressIndex: bdk.AddressIndex.lastUnused());
        var index = last.index;
        var scriptHex = _hex(last.address.scriptPubkey().bytes);
        var addrStr = last.address.asString();

        final cap = index + _kBitcoinNextUnusedScanCap;
        while (usedScripts.contains(scriptHex) && index < cap) {
          index++;
          final info = _bdk.wallet
              .getAddress(addressIndex: bdk.AddressIndex.peek(index: index));
          scriptHex = _hex(info.address.scriptPubkey().bytes);
          addrStr = info.address.asString();
        }

        if (usedScripts.contains(scriptHex)) {
          throw StateError(
            'Não foi possível encontrar um endereço não utilizado dentro '
            'da janela de varredura de $_kBitcoinNextUnusedScanCap índices.',
          );
        }

        // Advance BDK's internal counter so subsequent .increase() calls
        // start beyond this address.
        _bdk.wallet
            .getAddress(addressIndex: bdk.AddressIndex.reset(index: index));

        return WalletAddress(
          address: addrStr,
          chain: AddressChain.bitcoin,
          status: AddressStatus.unused,
          derivationIndex: index,
        );
      },
      (err, _) => WalletError(WalletErrorType.sdkError, err.toString()),
    );
  }

  Future<List<WalletAddress>> _scanBitcoinAddresses(int limit) async {
    final byScript = await _deriveBitcoinScriptMap(limit);

    // Group UTXOs by script hex.
    final utxosByScript = <String, List<bdk.LocalUtxo>>{};
    for (final u in _bdk.wallet.listUnspent()) {
      if (u.isSpent) continue;
      final hex = _hex(u.txout.scriptPubkey.bytes);
      if (!byScript.containsKey(hex)) continue;
      utxosByScript.putIfAbsent(hex, () => []).add(u);
    }

    // Mark scripts that have ever received funds, even if since spent.
    final receivedTo = <String>{...utxosByScript.keys};
    for (final tx in _bdk.wallet.listTransactions(includeRaw: true)) {
      final raw = tx.transaction;
      if (raw == null) continue;
      for (final out in raw.output()) {
        final hex = _hex(out.scriptPubkey.bytes);
        if (byScript.containsKey(hex)) receivedTo.add(hex);
      }
    }

    final result = <WalletAddress>[];
    byScript.forEach((scriptHex, entry) {
      final us = (utxosByScript[scriptHex] ?? const <bdk.LocalUtxo>[])
          .map((u) => AddressUtxo(
                address: entry.address,
                chain: AddressChain.bitcoin,
                outpoint: '${u.outpoint.txid}:${u.outpoint.vout}',
                value: u.txout.value,
              ))
          .toList();
      final received = us.fold<BigInt>(BigInt.zero, (s, u) => s + u.value);
      result.add(WalletAddress(
        address: entry.address,
        chain: AddressChain.bitcoin,
        status: receivedTo.contains(scriptHex)
            ? AddressStatus.used
            : AddressStatus.unused,
        derivationIndex: entry.index,
        receivedSats: received,
        utxos: us,
      ));
    });

    result.sort((a, b) => a.derivationIndex.compareTo(b.derivationIndex));
    return result;
  }

  Future<Map<String, _BitcoinDerivedEntry>> _deriveBitcoinScriptMap(
    int limit,
  ) async {
    final map = <String, _BitcoinDerivedEntry>{};
    for (int i = 0; i < limit; i++) {
      final info = _bdk.wallet
          .getAddress(addressIndex: bdk.AddressIndex.peek(index: i));
      final addr = info.address.asString();
      final hex = _hex(info.address.scriptPubkey().bytes);
      map[hex] = _BitcoinDerivedEntry(index: i, address: addr);
    }
    return map;
  }

  Set<String> _buildBitcoinUsedScriptSet() {
    final used = <String>{};
    for (final u in _bdk.wallet.listUnspent()) {
      used.add(_hex(u.txout.scriptPubkey.bytes));
    }
    for (final tx in _bdk.wallet.listTransactions(includeRaw: true)) {
      final raw = tx.transaction;
      if (raw == null) continue;
      for (final out in raw.output()) {
        used.add(_hex(out.scriptPubkey.bytes));
      }
    }
    return used;
  }

  Future<bool> _bitcoinAddressIsUsed(String scriptHex) async {
    for (final u in _bdk.wallet.listUnspent()) {
      if (_hex(u.txout.scriptPubkey.bytes) == scriptHex) return true;
    }
    for (final tx in _bdk.wallet.listTransactions(includeRaw: true)) {
      final raw = tx.transaction;
      if (raw == null) continue;
      for (final out in raw.output()) {
        if (_hex(out.scriptPubkey.bytes) == scriptHex) return true;
      }
    }
    return false;
  }

  // ────────────────────────────────────────────────────────────────────
  // Liquid (LWK)
  // ────────────────────────────────────────────────────────────────────

  @override
  TaskEither<WalletError, List<WalletAddress>> listLiquidAddresses({
    int limit = 100,
  }) {
    return TaskEither.tryCatch(
      () async => _scanLiquidAddresses(limit),
      (err, _) => WalletError(WalletErrorType.sdkError, err.toString()),
    );
  }

  @override
  TaskEither<WalletError, List<AddressUtxo>> listLiquidUtxos() {
    return TaskEither.tryCatch(
      () async {
        final utxos = await _lwk.wallet.utxos();
        return utxos
            .where((u) => !u.isSpent)
            .map((u) => AddressUtxo(
                  address: u.address.confidential,
                  chain: AddressChain.liquid,
                  outpoint: '${u.outpoint.txid}:${u.outpoint.vout}',
                  value: u.unblinded.value,
                  assetId: u.unblinded.asset,
                ))
            .toList();
      },
      (err, _) => WalletError(WalletErrorType.sdkError, err.toString()),
    );
  }

  @override
  TaskEither<WalletError, AddressMatch> isOwnedLiquidAddress(String address) {
    return TaskEither(() async {
      try {
        final utxos = await _lwk.wallet.utxos();
        final txs = await _lwk.wallet.txs();

        for (int i = 0; i < _kLiquidOwnershipScanLimit; i++) {
          final derived = await _lwk.wallet.address(index: i);
          final matches = derived.standard == address ||
              derived.confidential == address;
          if (!matches) continue;

          final addressUtxos = utxos.where((u) =>
              !u.isSpent && u.address.standard == derived.standard);
          final utxoCount = addressUtxos.length;
          var used = utxoCount > 0;
          if (!used) {
            for (final tx in txs) {
              if (tx.outputs
                  .any((o) => o.address.standard == derived.standard)) {
                used = true;
                break;
              }
            }
          }
          return Either.right(
            AddressMatch.owned(
              address: address,
              chain: AddressChain.liquid,
              status: used ? AddressStatus.used : AddressStatus.unused,
              derivationIndex: i,
              utxoCount: utxoCount,
            ),
          );
        }
        return Either.right(AddressMatch.notOwned(address));
      } catch (_) {
        // Treat any LWK validation/SDK error as "not owned" so the
        // multi-chain orchestrator can fall back cleanly.
        return Either.right(AddressMatch.notOwned(address));
      }
    });
  }

  @override
  TaskEither<WalletError, WalletAddress> getNextUnusedLiquidAddress() {
    return TaskEither.tryCatch(
      () async {
        final derived = await _lwk.wallet.addressLastUnused();
        // Defensive: confirm against current UTXOs / txs that this address
        // has no on-chain history.
        final utxos = await _lwk.wallet.utxos();
        final txs = await _lwk.wallet.txs();
        final std = derived.standard;
        final hasHistory = utxos.any((u) => u.address.standard == std) ||
            txs.any((tx) => tx.outputs.any((o) => o.address.standard == std));

        return WalletAddress(
          address: derived.confidential,
          chain: AddressChain.liquid,
          status: hasHistory ? AddressStatus.used : AddressStatus.unused,
          derivationIndex: derived.index ?? 0,
        );
      },
      (err, _) => WalletError(WalletErrorType.sdkError, err.toString()),
    );
  }

  Future<List<WalletAddress>> _scanLiquidAddresses(int limit) async {
    final byStd = <String, _LiquidDerivedEntry>{};
    for (int i = 0; i < limit; i++) {
      final addr = await _lwk.wallet.address(index: i);
      byStd[addr.standard] = _LiquidDerivedEntry(
        index: i,
        confidential: addr.confidential,
      );
    }

    final utxos = await _lwk.wallet.utxos();
    final txs = await _lwk.wallet.txs();

    final utxosByStd = <String, List<lwk.TxOut>>{};
    for (final u in utxos) {
      if (u.isSpent) continue;
      final std = u.address.standard;
      if (!byStd.containsKey(std)) continue;
      utxosByStd.putIfAbsent(std, () => []).add(u);
    }

    final receivedTo = <String>{...utxosByStd.keys};
    for (final tx in txs) {
      for (final out in tx.outputs) {
        final std = out.address.standard;
        if (byStd.containsKey(std)) receivedTo.add(std);
      }
    }

    final result = <WalletAddress>[];
    byStd.forEach((std, entry) {
      final us = (utxosByStd[std] ?? const <lwk.TxOut>[])
          .map((u) => AddressUtxo(
                address: entry.confidential,
                chain: AddressChain.liquid,
                outpoint: '${u.outpoint.txid}:${u.outpoint.vout}',
                value: u.unblinded.value,
                assetId: u.unblinded.asset,
              ))
          .toList();
      final received = us.fold<BigInt>(BigInt.zero, (s, u) => s + u.value);
      result.add(WalletAddress(
        address: entry.confidential,
        chain: AddressChain.liquid,
        status: receivedTo.contains(std)
            ? AddressStatus.used
            : AddressStatus.unused,
        derivationIndex: entry.index,
        receivedSats: received,
        utxos: us,
      ));
    });

    result.sort((a, b) => a.derivationIndex.compareTo(b.derivationIndex));
    return result;
  }
}

class _BitcoinDerivedEntry {
  final int index;
  final String address;
  const _BitcoinDerivedEntry({required this.index, required this.address});
}

class _LiquidDerivedEntry {
  final int index;
  final String confidential;
  const _LiquidDerivedEntry({required this.index, required this.confidential});
}

String _hex(List<int> bytes) {
  final buf = StringBuffer();
  for (final b in bytes) {
    buf.write((b & 0xff).toRadixString(16).padLeft(2, '0'));
  }
  return buf.toString();
}
