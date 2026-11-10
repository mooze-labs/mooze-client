import 'dart:convert';

/// A price history and the time its request started.
///
/// The prices are the closes of the history, oldest first. The last point
/// belongs to [fetchedAt], and each point before it lies one interval
/// earlier.
class CachedPriceHistory {
  final List<double> prices;
  final DateTime fetchedAt;

  CachedPriceHistory({required this.prices, required this.fetchedAt});

  /// Returns the age of the history at [now].
  Duration ageAt(DateTime now) => now.difference(fetchedAt);

  Map<String, dynamic> toJson() {
    return {'prices': prices, 'fetchedAt': fetchedAt.millisecondsSinceEpoch};
  }

  factory CachedPriceHistory.fromJson(Map<String, dynamic> json) {
    return CachedPriceHistory(
      prices: [
        for (final price in json['prices'] as List<dynamic>)
          (price as num).toDouble(),
      ],
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(json['fetchedAt'] as int),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static CachedPriceHistory fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return CachedPriceHistory.fromJson(json);
  }
}
