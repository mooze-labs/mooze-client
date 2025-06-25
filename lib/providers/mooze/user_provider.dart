import 'package:dart_nostr/dart_nostr.dart';
import 'package:mooze_mobile/models/user.dart';
import 'package:mooze_mobile/repositories/identity.dart';
import 'package:mooze_mobile/repositories/user.dart';
import 'package:mooze_mobile/services/mooze/referral.dart';
import 'package:mooze_mobile/services/mooze/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart';

const String backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: "api.mooze.app",
);

@riverpod
Future<UserRepository?> userRepository(Ref ref) async {
  final nostrPubKey = await NostrKeyStore.getPublicKey();

  if (nostrPubKey == null) {
    return null;
  }

  final userService = UserService(backendUrl: backendUrl);
  final referralService = ReferralService(backendUrl: backendUrl);
  return UserRepository(
    userService: userService,
    referralService: referralService,
    nostrPubKey: Nostr.instance.keysService.encodePublicKeyToNpub(nostrPubKey),
  );
}
