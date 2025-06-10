import 'package:shared_preferences/shared_preferences.dart';

class UserRepository {
  String _id;
  String _publicKey;
  String _referralCode;

  UserRepository({
    required String id,
    required String publicKey,
    required String referralCode,
  }) : _id = id,
       _publicKey = publicKey,
       _referralCode = referralCode;

  String get id => _id;
  String get publicKey => _publicKey;
  String get referralCode => _referralCode;

  void setReferralCode(String referralCode) => _referralCode = referralCode;

  Future<String> getAllowedSpendingAmount() async {
    // TODO: Implement this
    return "0";
  }

  factory UserRepository.fromJson(Map<String, dynamic> json) => UserRepository(
    id: json['id'],
    publicKey: json['publicKey'],
    referralCode: json['referralCode'],
  );
}
