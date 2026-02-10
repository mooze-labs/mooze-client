import '../../domain/entities/wallet_level_limits_entity.dart';

class WalletLevelLimitsModel {
  final int maxLimit;
  final int minLimit;

  const WalletLevelLimitsModel({
    required this.maxLimit,
    required this.minLimit,
  });

  factory WalletLevelLimitsModel.fromJson(Map<String, dynamic> json) {
    return WalletLevelLimitsModel(
      maxLimit: json['max_limit'] as int,
      minLimit: json['min_limit'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'max_limit': maxLimit, 'min_limit': minLimit};
  }

  WalletLevelLimitsEntity toEntity() {
    return WalletLevelLimitsEntity(maxLimit: maxLimit, minLimit: minLimit);
  }
}
