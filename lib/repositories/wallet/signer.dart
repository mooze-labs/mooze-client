import 'package:bdk_flutter/bdk_flutter.dart' as bitcoin;
import 'package:lwk/lwk.dart' as liquid;
import 'package:mooze_mobile/models/transaction.dart';
import 'package:mooze_mobile/repositories/wallet/node_config.dart';
import './wollet.dart';
import './mnemonic.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/network.dart' as network;

abstract class SignerRepository {
  Future<PartiallySignedTransaction> buildPartiallySignedTransaction(
    String recipient,
    int amount,
    double? feeRate,
  );
  Future<Transaction> signTransaction(PartiallySignedTransaction pst);
}

class BitcoinSignerRepository implements SignerRepository {
  final BitcoinWolletRepository _walletRepository;
  final MnemonicRepository _mnemonicRepository;

  BitcoinSignerRepository(this._walletRepository, this._mnemonicRepository);

  @override
  Future<PartiallySignedTransaction> buildPartiallySignedTransaction(
    String recipient,
    int amount,
    double? feeRate,
  ) async {
    final wallet = _walletRepository.wallet;
    final blockchain = _walletRepository.blockchain;
    if (wallet == null || blockchain == null) {
      throw Exception("Bitcoin wallet is not initialized.");
    }

    final balance = wallet.getBalance().total.toInt();
    if (balance < amount) {
      throw Exception("Insufficient funds.");
    }

    final address = await bitcoin.Address.fromString(
      s: recipient,
      network: _walletRepository.network!,
    );
    if (address.isValidForNetwork(network: _walletRepository.network!) ==
        false) {
      throw Exception("Invalid address.");
    }

    final estimateFeeEconomy = await blockchain.estimateFee(
      target: BigInt.from(3),
    );

    final script = address.scriptPubkey();
    final (psbt, txDetails) = await bitcoin.TxBuilder()
        .addRecipient(script, BigInt.from(amount))
        .feeRate(feeRate ?? estimateFeeEconomy.satPerVb)
        .enableRbf()
        .finish(wallet);

    final feeAmount = psbt.feeAmount();

    return PartiallySignedTransaction(
      pst: psbt,
      asset: AssetCatalog.bitcoin!,
      network: network.Network.bitcoin,
      recipient: recipient,
      feeAmount: feeAmount?.toInt() ?? 0,
    );
  }

  @override
  Future<Transaction> signTransaction(PartiallySignedTransaction pst) async {
    final blockchain = _walletRepository.blockchain;
    if (blockchain == null) {
      throw Exception("Bitcoin wallet is not initialized.");
    }

    final mnemonic = _mnemonicRepository.mnemonic;
    final psbt = pst.get<bitcoin.PartiallySignedTransaction>();

    // Create a descriptor key from the mnemonic
    final descriptorKey = await bitcoin.DescriptorSecretKey.create(
      network: _walletRepository.network!,
      mnemonic: await bitcoin.Mnemonic.fromString(mnemonic),
    );

    // Create a new wallet with the private key for signing
    final privateWallet = await bitcoin.Wallet.create(
      descriptor: await bitcoin.Descriptor.create(
        descriptor: descriptorKey.toString(),
        network: _walletRepository.network!,
      ),
      network: _walletRepository.network!,
      databaseConfig: const bitcoin.DatabaseConfig.memory(),
    );

    // Sign the PSBT
    final isFinalized = privateWallet.sign(psbt: psbt);
    if (!isFinalized) {
      throw Exception("Could not finalize transaction.");
    }

    final tx = psbt.extractTx();
    final res = await blockchain.broadcast(transaction: tx);
    final txid = tx.txid();

    return Transaction(
      txid: txid,
      destinationAddress: pst.recipient,
      asset: pst.asset,
      network: pst.network,
      feeAmount: pst.feeAmount ?? 0,
    );
  }
}

class LiquidSignerRepository implements SignerRepository {
  final LiquidWolletRepository _walletRepository;
  final MnemonicRepository _mnemonicRepository;
  final NodeConfigRepository _nodeConfigRepository;

  LiquidSignerRepository(
    this._walletRepository,
    this._mnemonicRepository,
    this._nodeConfigRepository,
  );

  @override
  Future<PartiallySignedTransaction> buildPartiallySignedTransaction(
    String recipient,
    int amount,
    double? feeRate,
  ) async {
    final wallet = _walletRepository.wallet;
    if (wallet == null) {
      throw Exception("Liquid wallet is not initialized.");
    }

    // For simplicity, use LBTC as asset
    final balances = await wallet.balances();
    final lbtc = balances.firstWhere(
      (b) => b.assetId == liquid.lBtcAssetId,
      orElse: () => throw Exception("No LBTC balance"),
    );

    if (lbtc.value < amount) {
      throw Exception("Insufficient funds.");
    }

    feeRate = feeRate ?? 1.0;
    final adjustedFeeRate = (feeRate * 100 < 26 ? 26.0 : feeRate * 100);

    final pset = await wallet.buildLbtcTx(
      sats: BigInt.from(amount),
      outAddress: recipient,
      feeRate: adjustedFeeRate,
      drain: false,
    );

    final psetAmounts = await wallet.decodeTx(pset: pset);

    return PartiallySignedTransaction(
      pst: pset,
      asset: AssetCatalog.getByLiquidAssetId(liquid.lBtcAssetId)!,
      network: network.Network.liquid!,
      recipient: recipient,
      feeAmount: psetAmounts.absoluteFees.toInt(),
    );
  }

  @override
  Future<Transaction> signTransaction(PartiallySignedTransaction pst) async {
    final wallet = _walletRepository.wallet;
    if (wallet == null) {
      throw Exception("Liquid wallet is not initialized.");
    }

    final mnemonic = _mnemonicRepository.mnemonic;
    final pset = pst.get<String>();

    final signedTxBytes = await wallet.signTx(
      mnemonic: mnemonic,
      pset: pset,
      network: _walletRepository.network!,
    );

    final txid = await liquid.Blockchain.broadcastSignedPset(
      electrumUrl: _nodeConfigRepository.liquidNode,
      signedPset: signedTxBytes,
    );

    return Transaction(
      txid: txid,
      destinationAddress: pst.recipient,
      asset: pst.asset,
      network: pst.network,
      feeAmount: pst.feeAmount ?? 0,
    );
  }
}
