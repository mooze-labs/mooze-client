import 'assets.dart';
import 'network.dart';

enum TransactionDirection { incoming, outgoing }

/// An abstracted partially signed transaction
class PartiallySignedTransaction {
  // BDK returns a PartiallySignedTransaction for the TxBuilder operations,
  // while LWK returns a String. A workaround is to create a custom class
  // that would wrap both types as a dynamic and contains the correct
  // network, that would be used to route the partially signed transaction
  // to the correct wallet.
  final dynamic pst;
  final Asset asset;
  final Network network;
  final String recipient;
  final int? feeAmount;

  PartiallySignedTransaction({
    required this.pst,
    required this.asset,
    required this.network,
    required this.recipient,
    this.feeAmount,
  });

  T get<T>() => pst as T;
}

class Transaction {
  final String txid;
  final String destinationAddress;
  final Network network;
  final Asset asset;
  final int feeAmount;

  Transaction({
    required this.txid,
    required this.destinationAddress,
    required this.asset,
    required this.network,
    required this.feeAmount,
  });
}

class TransactionRecord {
  final String txid;
  final DateTime? timestamp;
  final Asset asset;
  final int amount;
  final Network network;
  final TransactionDirection direction;

  TransactionRecord({
    required this.txid,
    required this.asset,
    required this.amount,
    required this.network,
    required this.direction,
    this.timestamp,
  });
}
