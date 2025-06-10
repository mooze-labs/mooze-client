import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bdk_flutter/bdk_flutter.dart' as bitcoin;
import 'package:lwk/lwk.dart' as liquid;
import 'package:path_provider/path_provider.dart';

import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/network.dart' as network;
import 'package:mooze_mobile/models/transaction.dart';

import './node_config.dart';

abstract class WolletRepository {
  Future<void> initialize(String descriptor);
  Future<void> sync();
  Future<String> generateAddress();
  Future<Map<String, int>> getBalance();
  Future<List<TransactionRecord>> getTransactionHistory();
}

class LiquidWolletRepository implements WolletRepository {
  final NodeConfigRepository nodeConfig;

  LiquidWolletRepository({required this.nodeConfig});

  liquid.Wallet? _wallet;
  liquid.Network? _network;

  liquid.Network? get network => _network;

  @override
  Future<void> initialize(String descriptor) async {
    final dir = await getApplicationSupportDirectory();
    final dbPath = "${dir.path}/lwk-db";

    _network =
        (nodeConfig.network == Network.mainnet)
            ? liquid.Network.mainnet
            : liquid.Network.testnet;

    try {
      _wallet = await liquid.Wallet.init(
        descriptor: liquid.Descriptor(ctDescriptor: descriptor),
        network: _network!,
        dbpath: dbPath,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error initializing liquid wallet: $e");
        print(stackTrace);
      }

      throw Exception("Error initializing liquid wallet: $e");
    }
  }

  @override
  Future<void> sync() async {
    if (_wallet == null) {
      throw Exception("Liquid wallet not initialized.");
    }

    await _wallet!.sync(
      electrumUrl: nodeConfig.liquidNode,
      validateDomain: true,
    );
  }

  @override
  Future<String> generateAddress() async {
    if (_wallet == null) {
      throw Exception("Liquid wallet not initialized.");
    }

    final address = await _wallet!.addressLastUnused();
    return address.confidential;
  }

  @override
  Future<Map<String, int>> getBalance() async {
    if (_wallet == null) {
      throw Exception("Liquid wallet not initialized.");
    }

    final balances = await _wallet!.balances();
    return Map.fromEntries(
      balances.map((balance) => MapEntry(balance.assetId, balance.value)),
    );
  }

  @override
  Future<List<TransactionRecord>> getTransactionHistory() async {
    if (_wallet == null) {
      throw Exception("Liquid wallet not initialized.");
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
                network: network.Network.liquid,
              ),
            )
            .toList();
    return transactions;
  }
}

class BitcoinWolletRepository implements WolletRepository {
  final NodeConfigRepository nodeConfig;

  bitcoin.Wallet? _wallet;
  Future<bitcoin.Blockchain>? _blockchain;
  late bitcoin.Network _network;

  BitcoinWolletRepository({required this.nodeConfig}) {
    _network =
        (nodeConfig.network == Network.mainnet)
            ? bitcoin.Network.bitcoin
            : bitcoin.Network.testnet;

    _blockchain = bitcoin.Blockchain.create(
      config: bitcoin.BlockchainConfig.electrum(
        config: bitcoin.ElectrumConfig(
          url: nodeConfig.bitcoinNode,
          retry: 5,
          stopGap: BigInt.from(10),
          validateDomain: false,
        ),
      ),
    );
  }

  Future<bitcoin.Blockchain>? get blockchain => _blockchain;
  bitcoin.Network get network => _network;
  int get balance => _wallet!.getBalance().total.toInt();

  @override
  Future<void> initialize(String descriptor) async {}
}
