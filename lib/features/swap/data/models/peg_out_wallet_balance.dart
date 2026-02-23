/// PegIn balances from the server status
class PegOutWalletBalance {
  final int available;

  PegOutWalletBalance({required this.available});

  factory PegOutWalletBalance.fromJson(Map<String, dynamic> json) {
    return PegOutWalletBalance(available: json['available']);
  }
}
