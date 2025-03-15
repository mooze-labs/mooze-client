import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mooze_mobile/models/payments.dart';
import 'package:uuid/uuid.dart';

String PIX_GATEWAY_URL = "";
String PIX_GATEWAY_TOKEN = "";

class PixGatewayRepository {
  Future<PixTransactionResponse?> newPixPayment(
    PixTransaction pixTransaction,
  ) async {
    var uuid = Uuid();
    final response = await http.post(
      Uri.https(PIX_GATEWAY_URL, "/api/deposit"),
      headers: <String, String>{
        "X-Nonce": uuid.v4().toString(),
        "X-Async": "auto",
        "Content-Type": "application/json",
        "Authorization": PIX_GATEWAY_TOKEN,
      },
      body: jsonEncode({
        "amountInCents": pixTransaction.brlAmount * 100,
        "depixAddress": pixTransaction.address,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      Map<String, dynamic> jsonResponse =
          json.decode(response.body)["response"];
      return PixTransactionResponse(
        qrImageUrl: jsonResponse["qrImageUrl"],
        qrCopyPaste: jsonResponse["qrCopyPaste"],
        id: jsonResponse["id"],
      );
    }

    print(
      "[ERROR] Não foi possível criar a transação: ${response.statusCode} - ${response.reasonPhrase}",
    );
    return null;
  }
}
