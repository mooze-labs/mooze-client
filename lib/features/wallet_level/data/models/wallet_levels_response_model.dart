import '../../domain/entities/wallet_level_entity.dart';
import 'wallet_level_limits_model.dart';

class WalletLevelsResponseModel {
  final Map<String, WalletLevelLimitsModel> data;

  const WalletLevelsResponseModel({required this.data});

  factory WalletLevelsResponseModel.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] as Map<String, dynamic>;
    final data = <String, WalletLevelLimitsModel>{};

    dataJson.forEach((key, value) {
      data[key] = WalletLevelLimitsModel.fromJson(
        value as Map<String, dynamic>,
      );
    });

    return WalletLevelsResponseModel(data: data);
  }

  Map<String, dynamic> toJson() {
    final dataJson = <String, dynamic>{};
    data.forEach((key, value) {
      dataJson[key] = value.toJson();
    });

    return {'data': dataJson};
  }

  List<WalletLevelEntity> toEntities() {
    final levels = <WalletLevelEntity>[];

    data.forEach((key, limitsModel) {
      final type = _stringToWalletLevelType(key);
      if (type != null) {
        final entity = WalletLevelEntity.fromLimits(
          type,
          limitsModel.toEntity(),
        );
        levels.add(entity);
      }
    });

    return levels;
  }

  WalletLevelType? _stringToWalletLevelType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'bronze':
        return WalletLevelType.bronze;
      case 'silver':
        return WalletLevelType.silver;
      case 'gold':
        return WalletLevelType.gold;
      case 'diamond':
        return WalletLevelType.diamond;
      default:
        return null;
    }
  }
}
