import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

const String backendUrl = String.fromEnvironment(
  "BACKEND_URL",
  defaultValue: "api.mooze.app",
);

class PhoneVerifyService {
  Future<String?> _getCurrentIp() async {
    final response = await http.get(
      Uri.parse('https://api.ipify.org?format=json'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['ip'];
    } else {
      if (kDebugMode) {
        debugPrint('Failed to get current IP');
      }
      return null;
    }
  }

  String _getPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return 'unknown';
    }
  }

  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  Future<int> verifyPhoneNumber(String phoneNumber) async {
    final platform = _getPlatform();
    final (appVersion, ip) = await (_getAppVersion(), _getCurrentIp()).wait;

    final url = Uri.https(backendUrl, "/api/v2/phone/verify");
    final response = await http.post(
      url,
      body: {
        'phone_number': phoneNumber,
        'platform': platform,
        'app_version': appVersion,
        'ip': ip,
      },
    );

    return response.statusCode;
  }
}
