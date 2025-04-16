import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationService {
  final String backendUrl;

  RegistrationService({required this.backendUrl});

  Future<bool?> registerUser(String pubDescriptor, String? referralCode) async {
    final url =
        (kDebugMode)
            ? Uri.http(backendUrl, "/users")
            : Uri.https(backendUrl, "/users");

    final hashedPubDescriptor =
        sha256.convert(utf8.encode(pubDescriptor)).toString();
    await saveHashedDescriptor(hashedPubDescriptor);

    final fcmToken = await FirebaseMessaging.instance.getToken();

    if (kDebugMode) {
      print("Hashed descriptor: $hashedPubDescriptor");
      print("FCM token: $fcmToken");
    }

    debugPrint("URL: $url");

    final response = await http.post(
      url,
      headers: <String, String>{"Content-Type": "application/json"},
      body: jsonEncode({
        "descriptor_hash": hashedPubDescriptor,
        "fcm_token": fcmToken,
        "referral_code": null,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      if (kDebugMode) {
        print("Error registering user: ${response.body}");
      }
      return false;
    }
  }

  Future<void> saveHashedDescriptor(String hashedDescriptor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hashed_descriptor', hashedDescriptor);
  }
}
