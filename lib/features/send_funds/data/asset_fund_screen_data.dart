class SendFundsScreenData {
  final String id;
  final String name;
  final String symbol;
  final String icon;
  final double amount;
  const SendFundsScreenData({
    required this.id,
    required this.name,
    required this.symbol,
    required this.icon,
    required this.amount,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SendFundsScreenData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
