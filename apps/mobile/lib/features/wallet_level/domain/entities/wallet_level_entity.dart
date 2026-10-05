import 'wallet_level_limits_entity.dart';

enum WalletLevelType { bronze, silver, gold, diamond }

/// Domain entity representing a wallet level tier.
///
/// Contains only business data — no Flutter framework dependencies.
/// Visual properties (icons, colors) are handled in the presentation layer.
class WalletLevelEntity {
  final WalletLevelType type;
  final String title;
  final String description;
  final List<String> benefits;
  final WalletLevelLimitsEntity limits;

  const WalletLevelEntity({
    required this.type,
    required this.title,
    required this.description,
    required this.benefits,
    required this.limits,
  });

  int get maxLimit => limits.maxLimit;
  int get minLimit => limits.minLimit;
  double get maxLimitInReais => limits.maxLimitInReais;
  double get minLimitInReais => limits.minLimitInReais;

  WalletLevelEntity copyWith({
    WalletLevelType? type,
    String? title,
    String? description,
    List<String>? benefits,
    WalletLevelLimitsEntity? limits,
  }) {
    return WalletLevelEntity(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      benefits: benefits ?? this.benefits,
      limits: limits ?? this.limits,
    );
  }

  @override
  String toString() {
    return 'WalletLevelEntity(type: $type, title: $title, limits: $limits)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletLevelEntity &&
        other.type == type &&
        other.title == title &&
        other.description == description &&
        other.limits == limits;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        title.hashCode ^
        description.hashCode ^
        limits.hashCode;
  }
}
