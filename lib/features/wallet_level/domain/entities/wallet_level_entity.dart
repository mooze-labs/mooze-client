import 'package:flutter/material.dart';
import 'wallet_level_limits_entity.dart';

enum WalletLevelType { bronze, silver, gold, diamond }

class WalletLevelEntity {
  final WalletLevelType type;
  final String title;
  final String description;
  final IconData icon;
  final List<String> benefits;
  final Color levelColor;
  final WalletLevelLimitsEntity limits;

  const WalletLevelEntity({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.benefits,
    required this.levelColor,
    required this.limits,
  });
  factory WalletLevelEntity.fromLimits(
    WalletLevelType type,
    WalletLevelLimitsEntity limits,
  ) {
    switch (type) {
      case WalletLevelType.bronze:
        return WalletLevelEntity(
          type: type,
          title: "Bronze",
          description:
              "Comece movimentando pequenos valores e desbloqueie os primeiros benefícios. Ideal para quem está começando no mundo das criptomoedas.",
          icon: Icons.workspace_premium,
          levelColor: const Color(0xFFCD7F32),
          limits: limits,
          benefits: const [],
        );

      case WalletLevelType.silver:
        return WalletLevelEntity(
          type: type,
          title: "Prata",
          description:
              "Quanto mais você gasta, mais sobe de nível. Alcance o nível Prata e aumente seus limites para movimentações maiores.",
          icon: Icons.workspace_premium,
          levelColor: const Color(0xFFC0C0C0),
          limits: limits,
          benefits: const [],
        );

      case WalletLevelType.gold:
        return WalletLevelEntity(
          type: type,
          title: "Ouro",
          description:
              "Mantenha uso frequente da carteira e alcance benefícios exclusivos e funcionalidades avançadas no nível Ouro.",
          icon: Icons.workspace_premium,
          levelColor: const Color(0xFFFFD700),
          limits: limits,
          benefits: const [],
        );

      case WalletLevelType.diamond:
        return WalletLevelEntity(
          type: type,
          title: "Diamante",
          description:
              "Você já movimenta grandes volumes. Tenha status de Diamante e acesso a limites premium para grandes investidores.",
          icon: Icons.diamond,
          levelColor: const Color(0xFFB9F2FF),
          limits: limits,
          benefits: const [],
        );
    }
  }

  int get maxLimit => limits.maxLimit;
  int get minLimit => limits.minLimit;
  double get maxLimitInReais => limits.maxLimitInReais;
  double get minLimitInReais => limits.minLimitInReais;
}
