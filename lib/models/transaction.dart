import 'assets.dart';
import 'network.dart';

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
  final Network network;
  final Asset asset;

  Transaction({required this.txid, required this.asset, required this.network});
}
