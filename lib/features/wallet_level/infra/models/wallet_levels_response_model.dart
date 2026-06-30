import 'package:mooze_mobile/features/wallet_level/domain/entities/wallet_level_entity.dart';
import 'package:mooze_mobile/features/wallet_level/domain/entities/wallet_level_limits_entity.dart';

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

  /// Transforms the API response into domain entities.
  /// Maps each level key to a fully-formed WalletLevelEntity
  /// with localized business data (title, description).
  List<WalletLevelEntity> toEntities() {
    final levels = <WalletLevelEntity>[];

    data.forEach((key, limitsModel) {
      final type = _stringToWalletLevelType(key);
      if (type != null) {
        levels.add(_createEntity(type, limitsModel.toEntity()));
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

  /// Maps WalletLevelType to its business properties.
  /// Title and description are localized Portuguese strings
  /// representing each tier's identity and value proposition.
  WalletLevelEntity _createEntity(
    WalletLevelType type,
    WalletLevelLimitsEntity limits,
  ) {
    switch (type) {
      case WalletLevelType.bronze:
        return WalletLevelEntity(
          type: type,
          title: 'Bronze',
          description:
              'Comece movimentando pequenos valores e desbloqueie os primeiros benefícios. Ideal para quem está começando no mundo das criptomoedas.',
          limits: limits,
          benefits: const [],
        );
      case WalletLevelType.silver:
        return WalletLevelEntity(
          type: type,
          title: 'Prata',
          description:
              'Quanto mais você gasta, mais sobe de nível. Alcance o nível Prata e aumente seus limites para movimentações maiores.',
          limits: limits,
          benefits: const [],
        );
      case WalletLevelType.gold:
        return WalletLevelEntity(
          type: type,
          title: 'Ouro',
          description:
              'Mantenha uso frequente da carteira e alcance benefícios exclusivos e funcionalidades avançadas no nível Ouro.',
          limits: limits,
          benefits: const [],
        );
      case WalletLevelType.diamond:
        return WalletLevelEntity(
          type: type,
          title: 'Diamante',
          description:
              'Você já movimenta grandes volumes. Tenha status de Diamante e acesso a limites premium para grandes investidores.',
          limits: limits,
          benefits: const [],
        );
    }
  }
}
