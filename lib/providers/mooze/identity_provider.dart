import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/repositories/identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'identity_provider.g.dart';

@riverpod
Future<String?> getNostrPubKey(Ref ref) async {
  return NostrKeyStore.getPublicKey();
}
