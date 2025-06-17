import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_id_provider.g.dart';

@Riverpod(keepAlive: true)
String walletId(Ref ref) {
  // For now, we'll use a default ID, but this could be loaded from storage
  // or user preferences in the future
  return "mainWallet";
}
