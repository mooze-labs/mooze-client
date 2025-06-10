import 'package:bdk_flutter/bdk_flutter.dart' as bitcoin;

import 'package:mooze_mobile/models/transaction.dart';
import './wollet.dart';

abstract class SignerRepository {
  Future<PartiallySignedTransaction> buildPartiallySignedTransaction(
    String recipient,
    int amount,
    double? feeRate,
  );
  Future<Transaction> signTransaction(PartiallySignedTransaction pst);
  Future<void> broadcastTransaction(Transaction transaction);
}

class BitcoinSignerRepository implements SignerRepository {
  final BitcoinWolletRepository wollet;

  BitcoinSignerRepository({required this.wollet});

  @override
  Future<PartiallySignedTransaction> buildPartiallySignedTransaction(
    String recipient,
    int amount,
    double? feeRate,
  ) async {
    final balance = wollet.balance;

    if (balance < amount) {
      throw Exception("Insufficient funds.");
    }

    final address = await bitcoin.Address.fromString(
      s: recipient,
      network: wollet.network,
    );

    if (address.isValidForNetwork(network: wollet.network) == false) {
      throw Exception("Invalid address.");
    }

    if (feeRate == null) {
      final blockchain = await wollet.blockchain;
      final estimateFeeEconomy = await blockchain!.estimateFee(
        target: BigInt.from(3),
      );

      feeRate = estimateFeeEconomy.satPerVb;
    }

    final script = address.scriptPubkey();
    final (psbt, txDetails) = await bitcoin.TxBuilder()
        .addRecipient(script, BigInt.from(amount))
        .feeRate(feeRate)
        .enableRbf()
        .finish

    final feeAmount = psbt.feeAmount();
  }
}
