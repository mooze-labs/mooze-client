import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/features/referral_input/external/datasources/referral_remote_datasource.dart';
import 'package:mooze_mobile/shared/user/entities/user.dart';
import 'package:mooze_mobile/shared/user/services/user_service.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class MockUserService extends Mock implements UserService {}

void main() {
  late MockUserService mockUserService;
  late ReferralRemoteDataSource dataSource;

  setUp(() {
    mockUserService = MockUserService();
    dataSource = ReferralRemoteDataSource(mockUserService);
  });

  User createUser({String? referredBy}) {
    return User(
      id: 'user-1',
      verificationLevel: 1,
      referredBy: referredBy,
      allowedSpending: 1000.0,
      dailySpending: 100.0,
      spendingLevel: 1,
      levelProgress: 0.5,
      valuesToReceive: {},
    );
  }

  group('ReferralRemoteDataSource', () {
    group('getExistingReferral', () {
      test('should return referral code when user has one', () async {
        // Arrange
        final user = createUser(referredBy: 'MOOZE123');
        when(() => mockUserService.getUser())
            .thenReturn(TaskEither.right(user));

        // Act
        final result = await dataSource.getExistingReferral();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, 'MOOZE123');
      });

      test('should return null when user has no referral code', () async {
        // Arrange
        final user = createUser(referredBy: null);
        when(() => mockUserService.getUser())
            .thenReturn(TaskEither.right(user));

        // Act
        final result = await dataSource.getExistingReferral();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNull);
      });

      test('should return null when referral code is empty string', () async {
        // Arrange
        final user = createUser(referredBy: '');
        when(() => mockUserService.getUser())
            .thenReturn(TaskEither.right(user));

        // Act
        final result = await dataSource.getExistingReferral();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNull);
      });

      test('should return Failure when user service fails', () async {
        // Arrange
        when(() => mockUserService.getUser())
            .thenReturn(TaskEither.left('Network error'));

        // Act
        final result = await dataSource.getExistingReferral();

        // Assert
        expect(result.isFailure, true);
        expect(result.error, 'Network error');
      });
    });

    group('validateReferralCode', () {
      test('should return true when code is valid', () async {
        // Arrange
        when(() => mockUserService.validateReferralCode('VALID'))
            .thenReturn(TaskEither.right(true));

        // Act
        final result = await dataSource.validateReferralCode('VALID');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, true);
      });

      test('should return false when code is invalid', () async {
        // Arrange
        when(() => mockUserService.validateReferralCode('INVALID'))
            .thenReturn(TaskEither.right(false));

        // Act
        final result = await dataSource.validateReferralCode('INVALID');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, false);
      });

      test('should return Failure when service fails', () async {
        // Arrange
        when(() => mockUserService.validateReferralCode('CODE'))
            .thenReturn(TaskEither.left('Server error'));

        // Act
        final result = await dataSource.validateReferralCode('CODE');

        // Assert
        expect(result.isFailure, true);
        expect(result.error, 'Server error');
      });
    });

    group('applyReferralCode', () {
      test('should return Success when code is applied', () async {
        // Arrange
        when(() => mockUserService.addReferral('MOOZE123'))
            .thenReturn(TaskEither.right(unit));

        // Act
        final result = await dataSource.applyReferralCode('MOOZE123');

        // Assert
        expect(result.isSuccess, true);
      });

      test('should return Failure when service fails', () async {
        // Arrange
        when(() => mockUserService.addReferral('CODE'))
            .thenReturn(TaskEither.left('Apply failed'));

        // Act
        final result = await dataSource.applyReferralCode('CODE');

        // Assert
        expect(result.isFailure, true);
        expect(result.error, 'Apply failed');
      });
    });
  });
}
