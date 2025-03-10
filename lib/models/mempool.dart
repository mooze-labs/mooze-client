class RecommendedFees {
  final num fastestFee;
  final num halfHourFee;
  final num hourFee;
  final num economyFee;
  final num minimumFee;

  RecommendedFees({
    required this.fastestFee,
    required this.halfHourFee,
    required this.hourFee,
    required this.economyFee,
    required this.minimumFee,
  });

  factory RecommendedFees.fromJson(Map<String, dynamic> json) {
    return RecommendedFees(
      fastestFee: json["fastestFee"],
      halfHourFee: json["halfHourFee"],
      hourFee: json["hourFee"],
      economyFee: json["economyFee"],
      minimumFee: json["minimumFee"],
    );
  }
}
