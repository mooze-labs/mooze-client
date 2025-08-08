import 'dart:convert';

import 'package:http/http.dart' as http;

const String versionDataUrl = String.fromEnvironment(
  "UPDATE_DATA_URL",
  defaultValue: "mooze-public.s3.us-east-1.amazonaws.com",
);
const String currentVersion = String.fromEnvironment(
  "CURRENT_BUILD_VERSION",
  defaultValue: "1.2.3-beta",
);

class UpdateData {
  final String currentVersion;

  UpdateData({required this.currentVersion});

  factory UpdateData.fromJson(Map<String, dynamic> json) {
    return UpdateData(currentVersion: json["current_version"]);
  }
}

class UpdateService {
  final http.Client client = http.Client();

  Future<UpdateData> getUpdateData() async {
    final response = await client.get(
      Uri.https(versionDataUrl, "/app_version.json"),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to get update info. Status code: ${response.statusCode}",
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    return UpdateData.fromJson(data);
  }
}

