/// Asset pair for market operations
class AssetPair {
  final String base;
  final String quote;

  AssetPair({required this.base, required this.quote});

  factory AssetPair.fromJson(Map<String, dynamic> json) {
    return AssetPair(base: json['base'], quote: json['quote']);
  }

  Map<String, dynamic> toJson() {
    return {'base': base, 'quote': quote};
  }
}
