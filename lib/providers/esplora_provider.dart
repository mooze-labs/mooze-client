import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'esplora_provider.g.dart';

@riverpod
Future<String?> getAssetInfo(Ref ref, String asset_id, bool mainnet) async {
	final network = (mainnet == true) ? "liquid" : "liquidtestnet";
	final response = await http.get(Uri.https('blockstream.info', '${network}/api/${asset_id}'));
}
