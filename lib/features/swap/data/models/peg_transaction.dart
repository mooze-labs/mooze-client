import 'tx_state.dart';

/// Transaction in a peg order
class PegTransaction {
  final String txHash;
  final int vout;
  final String status;
  final int amount;
  final int? payout;
  final String? payoutTxid;
  final DateTime createdAt;
  final TxState txState;
  final int txStateCode;
  final int? detectedConfs;
  final int? totalConfs;

  PegTransaction({
    required this.txHash,
    required this.vout,
    required this.status,
    required this.amount,
    this.payout,
    this.payoutTxid,
    required this.createdAt,
    required this.txState,
    required this.txStateCode,
    this.detectedConfs,
    this.totalConfs,
  });

  factory PegTransaction.fromJson(Map<String, dynamic> json) {
    TxState state;
    switch (json['tx_state']) {
      case 'InsufficientAmount':
        state = TxState.insufficientAmount;
        break;
      case 'Detected':
        state = TxState.detected;
        break;
      case 'Processing':
        state = TxState.processing;
        break;
      case 'Done':
        state = TxState.done;
        break;
      default:
        state = TxState.unknown;
    }

    return PegTransaction(
      txHash: json['tx_hash'],
      vout: json['vout'],
      status: json['status'],
      amount: json['amount'],
      payout: json['payout'],
      payoutTxid: json['payout_txid'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      txState: state,
      txStateCode: json['tx_state_code'],
      detectedConfs: json['detected_confs'],
      totalConfs: json['total_confs'],
    );
  }
}
