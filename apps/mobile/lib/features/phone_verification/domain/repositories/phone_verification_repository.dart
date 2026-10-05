import 'package:fpdart/fpdart.dart';

import '../entities.dart';

enum PhoneVerificationMethod { sms, telegram, whatsapp }

abstract class PhoneVerificationRepository {
  TaskEither<String, String> beginPhoneVerification(
    String phoneNumber,
    PhoneVerificationMethod method,
  );
  TaskEither<String, bool> verifyCode(String verificationId, String code);
  Stream<Either<String, VerificationStatus>> watchStatus(String verificationId);
}
