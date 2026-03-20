import 'package:mooze_mobile/features/referral_input/infra/datasources/referral_datasource.dart';
import 'package:mooze_mobile/shared/user/services/user_service.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Referral Remote Data Source Implementation (External Layer)
///
/// Delegates referral operations to the shared UserService,
/// which handles the actual REST API communication.
///
/// Converts fpdart's TaskEither pattern (used by UserService)
/// to the project's Result pattern used in the domain layer.
///
/// To switch to a different data source (e.g., direct Dio calls),
/// create a new implementation of ReferralDataSource and update
/// the provider — no other layers need to change.
class ReferralRemoteDataSource implements ReferralDataSource {
  final UserService _userService;

  const ReferralRemoteDataSource(this._userService);

  @override
  Future<Result<String?>> getExistingReferral() async {
    final either = await _userService.getUser().run();

    return either.match(
      (error) => Failure(error),
      (user) {
        final code = user.referredBy;
        if (code != null && code.isNotEmpty) {
          return Success(code);
        }
        return const Success(null);
      },
    );
  }

  @override
  Future<Result<bool>> validateReferralCode(String code) async {
    final either = await _userService.validateReferralCode(code).run();

    return either.match(
      (error) => Failure(error),
      (isValid) => Success(isValid),
    );
  }

  @override
  Future<Result<void>> applyReferralCode(String code) async {
    final either = await _userService.addReferral(code).run();

    return either.match(
      (error) => Failure(error),
      (_) => const Success(null),
    );
  }
}
