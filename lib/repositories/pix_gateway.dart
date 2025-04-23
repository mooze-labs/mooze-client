import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mooze_mobile/models/payments.dart';
import 'package:mooze_mobile/services/mooze/user.dart';

const BACKEND_URL = String.fromEnvironment(
  "BACKEND_URL",
  defaultValue: "api.mooze.app",
);

class PixGatewayRepository {
  Future<PixTransactionResponse?> newPixPayment(
    PixTransaction pixTransaction,
  ) async {
    final userService = UserService(backendUrl: BACKEND_URL);
    final userId = await userService.getUserId();

    final response = await http.post(
      Uri.https(BACKEND_URL, "/deposit"),
      headers: <String, String>{"Content-Type": "application/json"},
      body: jsonEncode({
        "amount_in_cents": pixTransaction.brlAmount,
        "address": pixTransaction.address,
        "user_id": userId!,
        "asset": pixTransaction.asset,
        "network": "liquid",
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      if (kDebugMode) {
        print("[DEBUG] PixTransactionResponse: $jsonResponse");
      }
      if (jsonResponse["error"] == null) {
        return PixTransactionResponse(
          qrImageUrl: jsonResponse["data"]["qr_image_url"],
          qrCopyPaste: jsonResponse["data"]["qr_copy_paste"],
          id: jsonResponse["data"]["transaction_id"],
        );
      } else {
        return null;
      }
    }

    if (response.statusCode == 403) {
      return null;
    }

    if (kDebugMode) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      print(jsonResponse["details"]);
    }
    return null;
  }
}
