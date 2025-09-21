import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class BreezPreparedStablecoinTransactionDto {
  final String destination;
  final double amount;
  final BigInt fees;
  final String asset;
  final bool drain;

  BreezPreparedStablecoinTransactionDto({
    required this.destination,
    required this.amount,
    required this.fees,
    required this.asset,
    this.drain = false,
  });

  PreparedStablecoinTransaction toDomain() {
    return PreparedStablecoinTransaction(
      destination: destination,
      asset: Asset.fromId(asset),
      amount: amount,
      networkFees: fees,
      drain: drain,
    );
  }
}

class BreezPreparedLayer2TransactionDto {
  final String destination;
  final Blockchain blockchain;
  final BigInt fees;
  final BigInt amount;
  final bool drain;

  BreezPreparedLayer2TransactionDto({
    required this.destination,
    required this.blockchain,
    required this.fees,
    required this.amount,
    this.drain = false,
  });

  PreparedLayer2BitcoinTransaction toDomain() {
    return PreparedLayer2BitcoinTransaction(
      destination: destination,
      amount: amount,
      networkFees: fees,
      blockchain: blockchain,
      drain: drain,
    );
  }
}

class BreezPreparedOnchainTransactionDto {
  final String destination;
  final BigInt fees;
  final BigInt amount;
  final bool drain;

  BreezPreparedOnchainTransactionDto({
    required this.destination,
    required this.fees,
    required this.amount,
    this.drain = false,
  });

  PreparedOnchainBitcoinTransaction toDomain() {
    return PreparedOnchainBitcoinTransaction(
      destination: destination,
      amount: amount,
      networkFees: fees,
      drain: drain,
    );
  }
}
