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

  Future<User?> getUserDetails() async {
    final userId = await getUserId();

    if (kDebugMode) {
      print("User ID: $userId");
    }

    if (userId == null) {
      return null;
    }

    final url =
        (kDebugMode)
            ? Uri.http(backendUrl, "/users/$userId")
            : Uri.https(backendUrl, "/users/$userId");
    final response = await http.get(url);

    if (kDebugMode) {
      print("Response: ${response.body}");
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data["data"]);
    } else if (response.statusCode == 404) {
      final registrationService = RegistrationService(backendUrl: backendUrl);
      await registrationService.registerUser(userId, null);

      return await getUserDetails();
    } else {
      if (kDebugMode) {
        print('Failed to fetch user details.');
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      return null;
    }
  }
}
