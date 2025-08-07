import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:mooze_mobile/services/mooze/registration.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/models/user.dart';

class UserService {
  final String backendUrl;

  UserService({required this.backendUrl});

  Future<String?> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('hashed_descriptor');
    return userId;
  }

  Future<User?> getUser(String userId) async {
    final url = Uri.https(backendUrl, "/users/$userId");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data["data"]);
    } else {
      return null;
    }
  }

  Future<User?> getUserDetails() async {
    if (kDebugMode) {
      print("=== GET USER DETAILS STARTED ===");
    }

    final userId = await getUserId();

    if (kDebugMode) {
      print("Fetching user details:");
      print("User ID: $userId");
    }

    if (userId == null) {
      if (kDebugMode) {
        print("No user ID found, returning null");
      }
      return null;
    }

    final url = Uri.https(backendUrl, "/users/$userId");
    if (kDebugMode) {
      print("Making request to: $url");
    }

    final response = await http.get(url);

    if (kDebugMode) {
      print("User details API response:");
      print("Status code: ${response.statusCode}");
      print("Response body: ${response.body}");
    }

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print("User found, returning user details");
      }
      final data = jsonDecode(response.body);
      return User.fromJson(data["data"]);
    } else if (response.statusCode == 404) {
      if (kDebugMode) {
        print("=== USER NOT FOUND, ATTEMPTING REGISTRATION ===");
      }
      final sharedPrefs = await SharedPreferences.getInstance();
      final hashedDescriptor = sharedPrefs.getString('hashed_descriptor');
      if (hashedDescriptor == null) {
        if (kDebugMode) {
          print("No hashed descriptor found, returning null");
        }
        return null;
      }

      final registrationService = RegistrationService(backendUrl: backendUrl);
      final registrationResult = await registrationService.registerUser(
        hashedDescriptor,
        null,
      );

      if (kDebugMode) {
        print("Registration result: $registrationResult");
        print("Retrying user details fetch after registration...");
      }
      return await getUserDetails();
    } else {
      if (kDebugMode) {
        print('=== FAILED TO FETCH USER DETAILS ===');
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      return null;
    }
  }
}
