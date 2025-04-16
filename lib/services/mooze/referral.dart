import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReferralService {
  final String backendUrl;

  ReferralService({required this.backendUrl});

  Future<bool> validateReferralCode(String referralCode) async {
    final url =
        (kDebugMode)
            ? Uri.http(backendUrl, "/referrals/$referralCode")
            : Uri.https(backendUrl, "/referrals/$referralCode");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['data'] == true) {
        await saveReferralCode(referralCode);
      }
      return data['data'] ?? false;
    } else {
      if (kDebugMode) {
        print("Error validating referral code: ${response.body}");
      }
      return false;
    }
  }

  Future<void> saveReferralCode(String referralCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('referralCode', referralCode);
  }
}
