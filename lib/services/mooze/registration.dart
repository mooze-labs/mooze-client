import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationService {
  final String backendUrl;

  RegistrationService({required this.backendUrl});

  Future<String?> registerUser(String? referralCode) async {
    final url =
        (kDebugMode)
            ? Uri.http(backendUrl, "/register")
            : Uri.https(backendUrl, "/register");
    final response = await http.post(
      url,
      headers: <String, String>{"Content-Type": "application/json"},
      body: jsonEncode({"referral_code": referralCode}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      debugPrint(data["user_id"]);
      return data['user_id'];
    } else {
      return null;
    }
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }
}
