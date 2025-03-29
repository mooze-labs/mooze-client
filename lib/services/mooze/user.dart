import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/models/user.dart';

class UserService {
  final String backendUrl;

  UserService({required this.backendUrl});

  Future<String?> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    return userId;
  }

  Future<User?> getUserDetails() async {
    final userId = await getUserId();

    if (userId == null) {
      return null;
    }

    final url =
        (kDebugMode)
            ? Uri.http(backendUrl, "/user/$userId")
            : Uri.https(backendUrl, "/user/$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      print('Failed to fetch user details.');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      return User(
        id: userId,
        dailySpending: 0,
        isFirstTransaction: true,
        verified: false,
      );
    }
  }
}
