import 'package:fpdart/fpdart.dart';

import '../../domain/entities.dart';
import '../../domain/repositories/phone_verification_repository.dart';

class MockPhoneVerificationRepositoryImpl
    implements PhoneVerificationRepository {
  @override
  TaskEither<String, String> beginPhoneVerification(
    String phoneNumber,
    PhoneVerificationMethod method,
  ) {
    return TaskEither.right('mock-verification-id');
  }

  @override
  TaskEither<String, bool> verifyCode(String verificationId, String code) {
    return TaskEither.right(true);
  }

  @override
  Stream<Either<String, VerificationStatus>> watchStatus(
    String verificationId,
  ) async* {
    yield Either.right(VerificationStatus(status: 'processing'));

    await Future.delayed(Duration(seconds: 2));

    yield Either.right(
      VerificationStatus(
        status: 'finished',
        message: 'Verification successful',
      ),
    );
  }
}
