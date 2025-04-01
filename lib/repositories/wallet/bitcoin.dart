import 'package:flutter/foundation.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';

import 'repository.dart';

import 'package:mooze_mobile/models/assets.dart' show OwnedAsset;
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/models/transaction.dart';

import 'package:bdk_flutter/bdk_flutter.dart' as bitcoin;

class BitcoinWalletRepository implements WalletRepository {
  bitcoin.Wallet? _wallet;
  bitcoin.Network? _network;
  bitcoin.Blockchain? _blockchain;

  @override
  Future<void> initializeWallet(bool mainnet, String mnemonic) async {
    _network = (mainnet) ? bitcoin.Network.bitcoin : bitcoin.Network.testnet;

    _blockchain = await bitcoin.Blockchain.create(
      config: bitcoin.BlockchainConfig.electrum(
        config: bitcoin.ElectrumConfig(
          stopGap: BigInt.from(10),
          timeout: 5,
          retry: 5,
          url: "blockstream.info:110",
          validateDomain: false,
        ),
      ),
    );

    final descriptorKey = await bitcoin.DescriptorSecretKey.create(
      network: _network!,
      mnemonic: await bitcoin.Mnemonic.fromString(mnemonic),
    );

    print("Descriptor: ${descriptorKey.toString()}");
    final derivationPath = await bitcoin.DerivationPath.create(
      path: "m/84h/0h/0h/0",
    );
    final descriptorPrivateKey = await descriptorKey.derive(derivationPath);

    final bitcoin.Descriptor descriptorPrivate = await bitcoin
        .Descriptor.create(
      descriptor: "wpkh(${descriptorPrivateKey.toString()})",
      network: _network!,
    );

    final derivationPathInt = await bitcoin.DerivationPath.create(
      path: "m/84h/1h/1h/0",
    );
    final descriptorPrivateKeyInt = await descriptorKey.derive(
      derivationPathInt,
    );

    final bitcoin.Descriptor descriptorPrivateInt = await bitcoin
        .Descriptor.create(
      descriptor: "wpkh(${descriptorPrivateKeyInt.toString()})",
      network: _network!,
    );

    _wallet = await bitcoin.Wallet.create(
      descriptor: descriptorPrivate,
      changeDescriptor: descriptorPrivateInt,
      network: _network!,
      databaseConfig: const bitcoin.DatabaseConfig.memory(),
    );

    await _wallet!.sync(blockchain: _blockchain!);

    if (kDebugMode) {
      print("Total balance: ${_wallet!.getBalance().total}");
      print("Spendable balance: ${_wallet!.getBalance().spendable}");
      print("Confirmed balance: ${_wallet!.getBalance().confirmed}");
      print("Unconfirmed balance: ${_wallet!.getBalance().untrustedPending}");
      final transactions = _wallet!.listTransactions(includeRaw: true);

      print("Transaction count: ${transactions.length}");
      for (var transaction in transactions) {
        print("Transaction details:");
        print("ID: ${transaction.txid}");
        print("Received: ${transaction.received}");
      }
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
  Future<List<OwnedAsset>> getOwnedAssets() async {
    if (_wallet == null) {
      throw Exception("Bitcoin wallet has not been initialized.");
    }

    final balance = _wallet!.getBalance().total.toInt();
    return [OwnedAsset.bitcoin(balance)];
  }

  @override
  Future<PartiallySignedTransaction> buildPartiallySignedTransaction(
    OwnedAsset asset,
    String recipient,
    int amount,
    double feeRate,
  ) async {
    if (_wallet == null) {
      throw Exception("Bitcoin wallet has not been initialized.");
    }

    final balance = _wallet!.getBalance().total.toInt();
    if (balance < amount) {
      throw Exception("Insufficient funds.");
    }

    final address = await bitcoin.Address.fromString(
      s: recipient,
      network: _network!,
    );
    if (address.isValidForNetwork(network: _network!) == false) {
      throw Exception("Invalid address.");
    }

    final script = address.scriptPubkey();
    final (psbt, txDetails) = await bitcoin.TxBuilder()
        .addRecipient(script, BigInt.from(amount))
        .feeRate(feeRate)
        .finish(_wallet!);

    final feeAmount =
        (psbt.feeAmount() != null) ? psbt.feeAmount()!.toInt() : null;

    final pst = PartiallySignedTransaction(
      pst: psbt,
      asset: asset.asset,
      network: Network.bitcoin,
      recipient: recipient,
      feeAmount: feeAmount,
    );

    return pst;
  }

  @override
  Future<Transaction> signTransaction(PartiallySignedTransaction pst) async {
    if (_wallet == null) {
      throw Exception("Bitcoin wallet is not initialized.");
    }

    if (_blockchain == null) {
      throw Exception("Not connected to Bitcoin nodes.");
    }

    final psbt = pst.get<bitcoin.PartiallySignedTransaction>();
    final isFinalized = await _wallet!.sign(psbt: psbt);

    if (!isFinalized) {
      throw Exception("Could not finalize transaction: ${psbt.txid}");
    }

    final tx = psbt.extractTx();
    final res = await _blockchain!.broadcast(transaction: tx);

    final txid = await tx.txid();
    return Transaction(
      txid: txid,
      destinationAddress: pst.recipient,
      asset: pst.asset,
      network: Network.bitcoin,
      feeAmount: pst.feeAmount ?? 0,
    );
  }
}
