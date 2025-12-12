import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mooze_mobile/shared/authentication/services.dart';
import 'package:mooze_mobile/shared/authentication/services/remote_auth_service_impl.dart';

const testMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

void main() {
  group('RemoteAuthenticationClient tests', () {
    late RemoteAuthenticationService remoteAuthenticationService;

    setUp(() {
      remoteAuthenticationService = RemoteAuthServiceImpl.withEcdsaClient(testMnemonic); 
    });

    test('should retrieve a challenge from the server', () async { 
      final challengeResult = await remoteAuthenticationService.requestLoginChallenge().run();
      expect(challengeResult.isRight(), true);

      final challenge = challengeResult.toNullable();
      if (challenge == null) {
        throw Exception("Challenge failed");
      }

      debugPrint(challenge.challengeId);
      debugPrint(challenge.message);
    });

  });
}