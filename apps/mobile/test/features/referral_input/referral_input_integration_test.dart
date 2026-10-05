import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/features/referral_input/domain/usecases/apply_referral_code_usecase.dart';
import 'package:mooze_mobile/features/referral_input/domain/usecases/get_existing_referral_usecase.dart';
import 'package:mooze_mobile/features/referral_input/external/datasources/referral_remote_datasource.dart';
import 'package:mooze_mobile/features/referral_input/infra/repositories/referral_repository_impl.dart';
import 'package:mooze_mobile/features/referral_input/presentation/controllers/referral_input_controller.dart';
import 'package:mooze_mobile/shared/user/entities/user.dart';
import 'package:mooze_mobile/shared/user/services/user_service.dart';
import 'package:fpdart/fpdart.dart';

class MockUserService extends Mock implements UserService {}

/// Integration test: validates the full flow from External → Infra → Domain → Presentation
void main() {
  late MockUserService mockUserService;
  late ReferralRemoteDataSource dataSource;
  late ReferralRepositoryImpl repository;
  late GetExistingReferralUseCase getExistingReferralUseCase;
  late ApplyReferralCodeUseCase applyReferralCodeUseCase;
  late ReferralInputController controller;

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

  setUp(() {
    mockUserService = MockUserService();
    dataSource = ReferralRemoteDataSource(mockUserService);
    repository = ReferralRepositoryImpl(dataSource);
    getExistingReferralUseCase = GetExistingReferralUseCase(repository);
    applyReferralCodeUseCase = ApplyReferralCodeUseCase(repository);
  });

  group('Referral Input Integration', () {
    group('full apply flow', () {
      test(
        'should apply referral code through all layers and update controller state',
        () async {
          // Arrange — user has no existing referral
          when(() => mockUserService.getUser())
              .thenReturn(TaskEither.right(createUser(referredBy: null)));
          when(() => mockUserService.validateReferralCode('MOOZE123'))
              .thenReturn(TaskEither.right(true));
          when(() => mockUserService.addReferral('MOOZE123'))
              .thenReturn(TaskEither.right(unit));

          controller = ReferralInputController(
            getExistingReferralUseCase: getExistingReferralUseCase,
            applyReferralCodeUseCase: applyReferralCodeUseCase,
          );
          await Future<void>.delayed(Duration.zero);

          // Assert initial state — no referral
          expect(controller.state.existingReferralCode, isNull);
          expect(controller.state.isLoading, false);

          // Act — apply a referral code
          final result = await controller.applyReferralCode('MOOZE123');

          // Assert — success state
          expect(result, true);
          expect(controller.state.isSuccess, true);
          expect(controller.state.existingReferralCode, 'MOOZE123');
          expect(controller.state.isLoading, false);
          expect(controller.state.error, isNull);
        },
      );

      test(
        'should fail gracefully when validation rejects the code',
        () async {
          // Arrange
          when(() => mockUserService.getUser())
              .thenReturn(TaskEither.right(createUser(referredBy: null)));
          when(() => mockUserService.validateReferralCode('INVALID'))
              .thenReturn(TaskEither.right(false));

          controller = ReferralInputController(
            getExistingReferralUseCase: getExistingReferralUseCase,
            applyReferralCodeUseCase: applyReferralCodeUseCase,
          );
          await Future<void>.delayed(Duration.zero);

          // Act
          final result = await controller.applyReferralCode('INVALID');

          // Assert
          expect(result, false);
          expect(controller.state.isSuccess, false);
          expect(controller.state.error, isNotNull);
          expect(controller.state.existingReferralCode, isNull);
          verifyNever(() => mockUserService.addReferral(any()));
        },
      );

      test(
        'should fail gracefully when network error occurs during validation',
        () async {
          // Arrange
          when(() => mockUserService.getUser())
              .thenReturn(TaskEither.right(createUser(referredBy: null)));
          when(() => mockUserService.validateReferralCode('CODE1'))
              .thenReturn(TaskEither.left('Network error'));

          controller = ReferralInputController(
            getExistingReferralUseCase: getExistingReferralUseCase,
            applyReferralCodeUseCase: applyReferralCodeUseCase,
          );
          await Future<void>.delayed(Duration.zero);

          // Act
          final result = await controller.applyReferralCode('CODE1');

          // Assert
          expect(result, false);
          expect(controller.state.error, isNotNull);
          expect(controller.state.existingReferralCode, isNull);
        },
      );
    });

    group('existing referral check flow', () {
      test(
        'should load existing referral code through all layers on init',
        () async {
          // Arrange
          when(() => mockUserService.getUser())
              .thenReturn(TaskEither.right(createUser(referredBy: 'EXISTING')));

          // Act
          controller = ReferralInputController(
            getExistingReferralUseCase: getExistingReferralUseCase,
            applyReferralCodeUseCase: applyReferralCodeUseCase,
          );
          await Future<void>.delayed(Duration.zero);

          // Assert
          expect(controller.state.existingReferralCode, 'EXISTING');
        },
      );

      test(
        'should handle null referral code from user service',
        () async {
          // Arrange
          when(() => mockUserService.getUser())
              .thenReturn(TaskEither.right(createUser(referredBy: null)));

          // Act
          controller = ReferralInputController(
            getExistingReferralUseCase: getExistingReferralUseCase,
            applyReferralCodeUseCase: applyReferralCodeUseCase,
          );
          await Future<void>.delayed(Duration.zero);

          // Assert
          expect(controller.state.existingReferralCode, isNull);
        },
      );

      test(
        'should handle user service failure on init gracefully',
        () async {
          // Arrange
          when(() => mockUserService.getUser())
              .thenReturn(TaskEither.left('Service unavailable'));

          // Act
          controller = ReferralInputController(
            getExistingReferralUseCase: getExistingReferralUseCase,
            applyReferralCodeUseCase: applyReferralCodeUseCase,
          );
          await Future<void>.delayed(Duration.zero);

          // Assert — should not crash, just have null referral
          expect(controller.state.existingReferralCode, isNull);
        },
      );
    });

    group('refresh flow', () {
      test(
        'should refresh and pick up newly applied referral code',
        () async {
          // Arrange — initially no referral
          when(() => mockUserService.getUser())
              .thenReturn(TaskEither.right(createUser(referredBy: null)));

          controller = ReferralInputController(
            getExistingReferralUseCase: getExistingReferralUseCase,
            applyReferralCodeUseCase: applyReferralCodeUseCase,
          );
          await Future<void>.delayed(Duration.zero);
          expect(controller.state.existingReferralCode, isNull);

          // Arrange — now user has a referral after refresh
          when(() => mockUserService.getUser())
              .thenReturn(
                TaskEither.right(createUser(referredBy: 'REFRESHED')),
              );

          // Act
          await controller.refreshUser();

          // Assert
          expect(controller.state.existingReferralCode, 'REFRESHED');
        },
      );
    });
  });
}
