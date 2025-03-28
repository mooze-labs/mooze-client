import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/utils/mnemonic.dart';

import 'repository.dart';

import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/models/transaction.dart';

import 'package:lwk/lwk.dart' as liquid;
import 'package:path_provider/path_provider.dart';
import 'package:restart_app/restart_app.dart';

const electrumUrl = "blockstream.info:995";

class LiquidWalletRepository implements WalletRepository {
  liquid.Wallet? _wallet;
  liquid.Network? _network;

  @override
  Future<void> initializeWallet(bool mainnet, String mnemonic) async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = "${dir.path}/lwk-db";

    _network = (mainnet) ? liquid.Network.mainnet : liquid.Network.testnet;

    final descriptor = await liquid.Descriptor.newConfidential(
      network: _network!,
      mnemonic: mnemonic,
    );

    try {
      _wallet = await liquid.Wallet.init(
        descriptor: descriptor,
        network: _network!,
        dbpath: dbPath,
      );
    } catch (e, stackTrace) {
      debugPrint("Failed to initialize Liquid wallet: $e");
      debugPrint("Stacktrace: $stackTrace");
      debugPrint("Clearing wallet in storage and initializing again");
      _clearWallet();
      debugPrint("Wallet cleared!");

      _wallet = await liquid.Wallet.init(
        descriptor: descriptor,
        network: _network!,
        dbpath: dbPath,
      );
    }
    debugPrint("Liquid wallet initialized");

    await _wallet!.sync(electrumUrl: electrumUrl, validateDomain: true);
    final txs = await _wallet!.txs();

    for (var tx in txs) {
      print(tx);
    }
  }

  @override
  Future<void> sync() async {
    if (_wallet == null) {
      throw Exception("Liquid wallet has not been initialized.");
    }

    _wallet!.sync(electrumUrl: electrumUrl, validateDomain: true);
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
  Future<List<OwnedAsset>> getOwnedAssets() async {
    if (_wallet == null) {
      debugPrint("Liquid wallet not initialized!");
      return [];
    }
    final balances = await _wallet!.balances();
    List<OwnedAsset> ownedAssets = [];

    for (final balance in balances) {
      final ownedAsset = await OwnedAsset.liquid(
        assetId: balance.assetId,
        amount: balance.value,
      );
      ownedAssets.add(ownedAsset);
    }

    if (ownedAssets.where((a) => a.asset.id == "depix").isEmpty) {
      ownedAssets.add(OwnedAsset.zero(AssetCatalog.getById("depix")!));
    }

    if (ownedAssets.where((a) => a.asset.id == "usdt").isEmpty) {
      ownedAssets.add(OwnedAsset.zero(AssetCatalog.getById("usdt")!));
    }

    return ownedAssets;
  }

  @override
  Future<PartiallySignedTransaction> buildPartiallySignedTransaction(
    OwnedAsset asset,
    String recipient,
    int amount,
    double feeRate,
  ) async {
    if (_wallet == null) {
      throw Exception("Liquid wallet has not been initialized.");
    }

    if (asset.asset.network != Network.liquid) {
      throw Exception("Asset is not a Liquid asset.");
    }

    if (asset.asset.liquidAssetId == null) {
      throw Exception("Asset ID has not been provided.");
    }

    if (amount > asset.amount) {
      throw Exception("Insufficient funds.");
    }

    if (asset.asset.liquidAssetId! == liquid.lBtcAssetId) {
      return _buildLiquidBitcoinTransaction(
        asset,
        recipient,
        amount,
        (feeRate * 100 < 26 ? 26 : feeRate * 100),
      );
    }

    return _buildLiquidAssetTransaction(
      asset,
      recipient,
      amount,
      (feeRate * 100 < 26 ? 26 : feeRate * 100),
    );
  }

  Future<PartiallySignedTransaction> _buildLiquidAssetTransaction(
    OwnedAsset asset,
    String recipient,
    int amount,
    double feeRate,
  ) async {
    final pset = await _wallet!.buildAssetTx(
      sats: BigInt.from(amount),
      outAddress: recipient,
      feeRate: feeRate,
      asset: asset.asset.liquidAssetId!,
    );

    final psetAmounts = await _wallet!.decodeTx(pset: pset);
    final pst = PartiallySignedTransaction(
      pst: pset,
      asset: asset.asset,
      network: Network.liquid,
      recipient: recipient,
      feeAmount: psetAmounts.absoluteFees.toInt(),
    );

    return pst;
  }

  Future<PartiallySignedTransaction> _buildLiquidBitcoinTransaction(
    OwnedAsset asset,
    String recipient,
    int amount,
    double feeRate,
  ) async {
    final pset = await _wallet!.buildLbtcTx(
      sats: BigInt.from(amount),
      outAddress: recipient,
      feeRate: feeRate,
      drain: false,
    );

    final psetAmounts = await _wallet!.decodeTx(pset: pset);

    final pst = PartiallySignedTransaction(
      pst: pset,
      asset: asset.asset,
      network: Network.liquid,
      recipient: recipient,
      feeAmount: psetAmounts.absoluteFees.toInt(),
    );

    return pst;
  }

  int _calculateFeeAmount(int recipients, int outputs) {
    const feeRate = 0.1;
    const fixedWeight = 44;
    const singlesigVinWeight = 367;
    const voutWeight = 4810;
    const feeWeight = 178;

    final int txSize =
        fixedWeight +
        singlesigVinWeight * recipients +
        voutWeight * outputs +
        feeWeight;

    final vsize = (txSize + 3) / 4;
    return (vsize * feeRate).ceil();
  }

  @override
  Future<Transaction> signTransaction(PartiallySignedTransaction pst) async {
    if (_wallet == null) {
      throw Exception("Liquid wallet is not initialized.");
    }
    if (pst.network != Network.liquid) {
      throw Exception("Not a Liquid transaction.");
    }

    if (pst.asset.liquidAssetId == null) {
      throw Exception("Asset is not a Liquid asset.");
    }

    return _signLiquidBitcoinTransaction(pst);
  }

  Future<Transaction> _signLiquidBitcoinTransaction(
    PartiallySignedTransaction pst,
  ) async {
    final pset = pst.get<String>();
    final mnemonic = await MnemonicHandler().retrieveWalletMnemonic(
      "mainWallet",
    );

    final signedTxBytes = await _wallet!.signTx(
      mnemonic: mnemonic!,
      pset: pset,
      network: _network!,
    );

    final tx = await liquid.Wallet.broadcastTx(
      electrumUrl: electrumUrl,
      txBytes: signedTxBytes,
    );

    return Transaction(
      txid: tx,
      destinationAddress: pst.recipient,
      network: Network.liquid,
      asset: pst.asset,
      feeAmount: pst.feeAmount ?? 0,
    );
  }

  Future<String> signPsetWithExtraDetails(String pset) async {
    if (_wallet == null) {
      throw Exception("Liquid Wallet not initialized.");
    }

    final mnemonic = await MnemonicHandler().retrieveWalletMnemonic(
      "mainWallet",
    );

    final signedPset = await _wallet!.signedPsetWithExtraDetails(
      pset: pset,
      mnemonic: mnemonic!,
      network: _network!,
    );
    return signedPset;
  }

  /*
  Future<Transaction> _signLiquidAssetTransaction(
    PartiallySignedTransaction pst,
  ) async {
    final pset = pst.get<String>();
    final mnemonic = await MnemonicHandler().retrieveWalletMnemonic(
      "mainWallet",
    );

    final signedAssetPset = await _wallet!.signedPsetWithExtraDetails(
      pset: pset,
      mnemonic: mnemonic!,
      network: _network!,
    );
    final signedTxBytes = await _wallet!.signTx(
      pset: signedAssetPset,
      mnemonic: mnemonic,
      network: _network!,
    );

    final tx = await liquid.Wallet.broadcastTx(
      electrumUrl: electrumUrl,
      txBytes: signedTxBytes,
    );

    return Transaction(txid: tx, network: Network.liquid, asset: pst.asset);
  }
  */

  Future<List<liquid.TxOut>> fetchUtxos() async {
    if (_wallet == null) {
      throw Exception("Liquid wallet is not initialized.");
    }

    final utxos = await _wallet!.utxos();
    return utxos;
  }

  Future<void> _clearWallet() async {
    final localDir = await getApplicationDocumentsDirectory();
    final dbPath = "${localDir.path}/lwk-db";

    final dir = Directory(dbPath);
    dir.deleteSync(recursive: true);
    Directory(dbPath).createSync();

    Restart.restartApp(
      notificationTitle: "Reinicializando aplicativo",
      notificationBody:
          "Um erro foi detectado. O cache será resetado e o aplicativo reiniciará.",
    );
  }

  Future<List<TransactionRecord>> getTransactionHistory() async {
    if (_wallet == null) {
      throw Exception("Liquid wallet is not initialized.");
    }

    var history = await _wallet!.txs();
    history = history.where(
      (tx) => AssetCatalog.getByLiquidAssetId(tx.balances[0].assetId) != null,
    ).toList();

    final transactions =
        history
            .map(
              (tx) => TransactionRecord(
                txid: tx.txid,
                timestamp:
                    tx.timestamp != null
                        ? DateTime.fromMillisecondsSinceEpoch(tx.timestamp! * 1000)
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
}
