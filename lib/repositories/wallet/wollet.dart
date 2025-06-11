import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bdk_flutter/bdk_flutter.dart' as bitcoin;
import 'package:lwk/lwk.dart' as liquid;
import 'package:path_provider/path_provider.dart';

import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/network.dart' show Network;
import 'package:mooze_mobile/models/transaction.dart';

import 'node_config.dart' as node_config;

abstract class WolletRepository {
  Future<void> initialize(String descriptor);
  Future<void> sync();
  Future<String> generateAddress();
  Future<Map<String, int>> getBalance();
  Future<List<TransactionRecord>> getTransactionHistory();
}

class BitcoinWolletRepository implements WolletRepository {
  bitcoin.Wallet? _wallet;
  bitcoin.Network? _network;
  bitcoin.Blockchain? _blockchain;
  final node_config.NodeConfigRepository _nodeConfig;

  BitcoinWolletRepository(this._nodeConfig);

  bitcoin.Wallet? get wallet => _wallet;
  bitcoin.Network? get network => _network;
  bitcoin.Blockchain? get blockchain => _blockchain;

  @override
  Future<void> initialize(String descriptor) async {
    _network =
        _nodeConfig.network == node_config.Network.mainnet
            ? bitcoin.Network.bitcoin
            : bitcoin.Network.testnet;

    _blockchain = await bitcoin.Blockchain.create(
      config: bitcoin.BlockchainConfig.electrum(
        config: bitcoin.ElectrumConfig(
          stopGap: BigInt.from(10),
          timeout: 5,
          retry: 5,
          url: _nodeConfig.bitcoinNode,
          validateDomain: false,
        ),
      ),
    );

    final bitcoin.Descriptor descriptorPublic = await bitcoin.Descriptor.create(
      descriptor: descriptor,
      network: _network!,
    );

    _wallet = await bitcoin.Wallet.create(
      descriptor: descriptorPublic,
      network: _network!,
      databaseConfig: const bitcoin.DatabaseConfig.memory(),
    );

    await _wallet!.sync(blockchain: _blockchain!);

    if (kDebugMode) {
      print("Total balance: ${_wallet!.getBalance().total}");
      print("Spendable balance: ${_wallet!.getBalance().spendable}");
      print("Confirmed balance: ${_wallet!.getBalance().confirmed}");
      print("Unconfirmed balance: ${_wallet!.getBalance().untrustedPending}");
    }
  }

  @override
  Future<void> sync() async {
    if (_wallet == null || _blockchain == null) {
      throw Exception("Bitcoin wallet has not been initialized.");
    }

    await _wallet!.sync(blockchain: _blockchain!);
  }

  @override
  Future<String> generateAddress() async {
    if (_wallet == null) {
      throw Exception("Bitcoin wallet has not been initialized.");
    }

    return _wallet!
        .getAddress(addressIndex: bitcoin.AddressIndex.increase())
        .address
        .asString();
  }

  @override
  Future<Map<String, int>> getBalance() async {
    if (_wallet == null) {
      throw Exception("Bitcoin wallet has not been initialized.");
    }

    final balance = _wallet!.getBalance();
    return {
      "total": balance.total.toInt(),
      "spendable": balance.spendable.toInt(),
      "confirmed": balance.confirmed.toInt(),
      "untrusted_pending": balance.untrustedPending.toInt(),
    };
  }

  @override
  Future<List<TransactionRecord>> getTransactionHistory() async {
    if (_wallet == null) {
      throw Exception("Bitcoin wallet is not initialized.");
    }

    final txHistory = _wallet!.listTransactions(includeRaw: true);
    final transactions =
        txHistory
            .map(
              (tx) => TransactionRecord(
                txid: tx.txid,
                timestamp:
                    tx.confirmationTime != null
                        ? DateTime.fromMillisecondsSinceEpoch(
                          tx.confirmationTime!.timestamp.toInt() * 1000,
                        )
                        : null,
                asset: AssetCatalog.bitcoin!,
                amount:
                    tx.sent.toInt() == 0
                        ? tx.received.toInt()
                        : tx.sent.toInt(),
                direction:
                    tx.sent.toInt() == 0
                        ? TransactionDirection.incoming
                        : TransactionDirection.outgoing,
                network: Network.bitcoin,
              ),
            )
            .toList();

    return transactions;
  }
}

class LiquidWolletRepository implements WolletRepository {
  liquid.Wallet? _wallet;
  liquid.Network? _network;

  final node_config.NodeConfigRepository _nodeConfig;

  LiquidWolletRepository(this._nodeConfig);

  liquid.Wallet? get wallet => _wallet;
  liquid.Network? get network => _network;

  @override
  Future<void> initialize(String descriptor) async {
    final dir = await getApplicationSupportDirectory();
    final dbPath = "${dir.path}/lwk-db";

    _network =
        _nodeConfig.network == node_config.Network.mainnet
            ? liquid.Network.mainnet
            : liquid.Network.testnet;

    final liquidDescriptor = liquid.Descriptor(ctDescriptor: descriptor);

    try {
      _wallet = await liquid.Wallet.init(
        descriptor: liquidDescriptor,
        network: _network!,
        dbpath: dbPath,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint("Failed to initialize Liquid wallet: $e");
        debugPrint("Stacktrace: $stackTrace");
        debugPrint("Clearing wallet in storage and initializing again");
      }
      _clearWallet();
      if (kDebugMode) {
        debugPrint("Wallet cleared!");
      }

      _wallet = await liquid.Wallet.init(
        descriptor: liquidDescriptor,
        network: _network!,
        dbpath: dbPath,
      );
    }

    if (kDebugMode) {
      debugPrint("Liquid wallet initialized");
    }

    await _wallet!.sync_(
      electrumUrl: _nodeConfig.liquidNode,
      validateDomain: true,
    );
  }

  @override
  Future<void> sync() async {
    if (_wallet == null) {
      throw Exception("Liquid wallet has not been initialized.");
    }

    await _wallet!.sync_(
      electrumUrl: _nodeConfig.liquidNode,
      validateDomain: true,
    );
  }

  @override
  Future<String> generateAddress() async {
    if (_wallet == null) {
      throw Exception("Liquid wallet has not been initialized.");
    }

    final address = await _wallet!.addressLastUnused();
    return address.confidential;
  }

  @override
  Future<Map<String, int>> getBalance() async {
    if (_wallet == null) {
      throw Exception("Liquid wallet has not been initialized.");
    }

    final balances = await _wallet!.balances();
    Map<String, int> balanceMap = {};

    for (final balance in balances) {
      final asset = AssetCatalog.getByLiquidAssetId(balance.assetId);
      if (asset != null) {
        balanceMap[asset.id] = balance.value;
      }
    }

    // Ensure default assets are always present
    if (!balanceMap.containsKey("depix")) {
      balanceMap["depix"] = 0;
    }
    if (!balanceMap.containsKey("usdt")) {
      balanceMap["usdt"] = 0;
    }

    return balanceMap;
  }

  @override
  Future<List<TransactionRecord>> getTransactionHistory() async {
    if (_wallet == null) {
      throw Exception("Liquid wallet is not initialized.");
    }

    var history = await _wallet!.txs();
    history =
        history
            .where(
              (tx) =>
                  AssetCatalog.getByLiquidAssetId(tx.balances[0].assetId) !=
                  null,
            )
            .toList();

    final transactions =
        history
            .map(
              (tx) => TransactionRecord(
                txid: tx.txid,
                timestamp:
                    tx.timestamp != null
                        ? DateTime.fromMillisecondsSinceEpoch(
                          tx.timestamp! * 1000,
                        )
                        : null,
                asset: AssetCatalog.getByLiquidAssetId(tx.balances[0].assetId)!,
                amount: tx.balances[0].value,
                direction:
                    tx.kind == "incoming"
                        ? TransactionDirection.incoming
                        : TransactionDirection.outgoing,
                network: Network.liquid,
              ),
            )
            .toList();

    return transactions;
  }

  Future<void> _clearWallet() async {
    final localDir = await getApplicationSupportDirectory();
    final dbPath = "${localDir.path}/lwk-db";

    final dir = Directory(dbPath);
    dir.deleteSync(recursive: true);
    Directory(dbPath).createSync();
  }
}
