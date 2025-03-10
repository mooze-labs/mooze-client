import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mooze_mobile/models/mempool.dart';

abstract class MempoolRepository {
  final String baseUrl;

  MempoolRepository(this.baseUrl);

  Future<RecommendedFees> getRecommendedFees();
}

class GenericMempoolRepository implements MempoolRepository {
  @override
  final String baseUrl;

  GenericMempoolRepository(this.baseUrl);

  @override
  Future<RecommendedFees> getRecommendedFees() async {
    final response = await http.get(Uri.parse("$baseUrl/v1/fees/recommended"));

    if (response.statusCode == 200) {
      return RecommendedFees.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load recommended network fees.");
    }
  }
}

class LiquidMempoolRepository extends GenericMempoolRepository {
  LiquidMempoolRepository() : super("https://liquid.network/api");
}

class BitcoinMempoolRepository extends GenericMempoolRepository {
  BitcoinMempoolRepository() : super("https://mempool.space/api");
}
