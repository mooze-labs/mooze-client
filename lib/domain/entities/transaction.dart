import 'chain.dart';

enum TransactionDirection { incoming, outgoing, internal }

enum TransactionStatus { pending, confirmed, failed }

/// Domain transaction. Contains only fields the wallet needs across chains.
/// SDK-specific metadata stays inside the infra layer.
class Transaction {
  const Transaction({
    required this.id,
    required this.chain,
    required this.direction,
    required this.status,
    required this.amountSat,
    required this.feeSat,
    required this.timestamp,
    this.confirmations = 0,
    this.assetId,
    this.address,
    this.label,
  });

  final String id;
  final ChainId chain;
  final TransactionDirection direction;
  final TransactionStatus status;

  /// Amount in satoshis (or asset minimal units, when [assetId] is set).
  /// Sign convention: always positive; use [direction] to interpret.
  final int amountSat;
  final int feeSat;
  final DateTime timestamp;
  final int confirmations;

  /// Optional asset id for Liquid transactions.
  final String? assetId;
  final String? address;
  final String? label;

  Transaction copyWith({
    TransactionStatus? status,
    int? confirmations,
    String? label,
  }) {
    return Transaction(
      id: id,
      chain: chain,
      direction: direction,
      status: status ?? this.status,
      amountSat: amountSat,
      feeSat: feeSat,
      timestamp: timestamp,
      confirmations: confirmations ?? this.confirmations,
      assetId: assetId,
      address: address,
      label: label ?? this.label,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'chain': chain.name,
        'direction': direction.name,
        'status': status.name,
        'amount_sat': amountSat,
        'fee_sat': feeSat,
        'timestamp_ms': timestamp.millisecondsSinceEpoch,
        'confirmations': confirmations,
        'asset_id': assetId,
        'address': address,
        'label': label,
      };

  static Transaction fromMap(Map<String, Object?> m) {
    return Transaction(
      id: m['id'] as String,
      chain: ChainId.values.byName(m['chain'] as String),
      direction:
          TransactionDirection.values.byName(m['direction'] as String),
      status: TransactionStatus.values.byName(m['status'] as String),
      amountSat: (m['amount_sat'] as num).toInt(),
      feeSat: (m['fee_sat'] as num).toInt(),
      timestamp:
          DateTime.fromMillisecondsSinceEpoch((m['timestamp_ms'] as num).toInt()),
      confirmations: (m['confirmations'] as num?)?.toInt() ?? 0,
      assetId: m['asset_id'] as String?,
      address: m['address'] as String?,
      label: m['label'] as String?,
    );
  }
}
