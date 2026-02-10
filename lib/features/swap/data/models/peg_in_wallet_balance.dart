/// PegIn balances from the server status
class PegInWalletBalance {
  final int available;

  PegInWalletBalance({required this.available});

  factory PegInWalletBalance.fromJson(Map<String, dynamic> json) {
    return PegInWalletBalance(available: json['available']);
  }
}
