import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/features/referral_input/domain/usecases/apply_referral_code_usecase.dart';
import 'package:mooze_mobile/features/referral_input/domain/usecases/get_existing_referral_usecase.dart';
import 'package:mooze_mobile/features/referral_input/presentation/controllers/referral_input_controller.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class MockGetExistingReferralUseCase extends Mock
    implements GetExistingReferralUseCase {}

class MockApplyReferralCodeUseCase extends Mock
    implements ApplyReferralCodeUseCase {}

void main() {
  late MockGetExistingReferralUseCase mockGetExistingReferral;
  late MockApplyReferralCodeUseCase mockApplyReferralCode;

  setUp(() {
    mockGetExistingReferral = MockGetExistingReferralUseCase();
    mockApplyReferralCode = MockApplyReferralCodeUseCase();
  });

  ReferralInputController createController() {
    return ReferralInputController(
      getExistingReferralUseCase: mockGetExistingReferral,
      applyReferralCodeUseCase: mockApplyReferralCode,
    );
  }

  group('ReferralInputState', () {
    test('should have correct default values', () {
      const state = ReferralInputState();

      expect(state.existingReferralCode, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isSuccess, false);
    });

    test('should copy with new values', () {
      const state = ReferralInputState();
      final updated = state.copyWith(
        existingReferralCode: 'CODE1',
        isLoading: true,
        error: 'some error',
        isSuccess: true,
      );

      expect(updated.existingReferralCode, 'CODE1');
      expect(updated.isLoading, true);
      expect(updated.error, 'some error');
      expect(updated.isSuccess, true);
    });

    test('should clear existingReferralCode when flag is set', () {
      const state = ReferralInputState(existingReferralCode: 'CODE1');
      final updated = state.copyWith(clearExistingReferralCode: true);

      expect(updated.existingReferralCode, isNull);
    });

    test('should clear error when copyWith sets it to null', () {
      const state = ReferralInputState(error: 'old error');
      final updated = state.copyWith(error: null);

      expect(updated.error, isNull);
    });
  });

  group('ReferralInputController', () {
    group('initialization', () {
      test('should check existing referral on creation', () async {
        // Arrange
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Success('EXISTING'));

        // Act
        final controller = createController();

        // Wait for the async init to complete
        await Future<void>.delayed(Duration.zero);

        // Assert
        expect(controller.state.existingReferralCode, 'EXISTING');
        verify(() => mockGetExistingReferral()).called(1);
      });

      test('should set null when no existing referral found', () async {
        // Arrange
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Success(null));

        // Act
        final controller = createController();
        await Future<void>.delayed(Duration.zero);

        // Assert
        expect(controller.state.existingReferralCode, isNull);
      });

      test('should clear referral code when check fails', () async {
        // Arrange
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Failure('Error'));

        // Act
        final controller = createController();
        await Future<void>.delayed(Duration.zero);

        // Assert
        expect(controller.state.existingReferralCode, isNull);
      });
    });

    group('applyReferralCode', () {
      test('should return false when code is empty', () async {
        // Arrange
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Success(null));
        final controller = createController();
        await Future<void>.delayed(Duration.zero);

        // Act
        final result = await controller.applyReferralCode('');

        // Assert
        expect(result, false);
        verifyNever(() => mockApplyReferralCode(any()));
      });

      test('should set loading state while applying', () async {
        // Arrange
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Success(null));

        // Use a completer to control when the use case resolves,
        // allowing us to observe the intermediate loading state.
        final completer = Completer<Result<void>>();
        when(() => mockApplyReferralCode('CODE1'))
            .thenAnswer((_) => completer.future);

        final controller = createController();
        await Future<void>.delayed(Duration.zero);

        // Act — start applying but don't complete yet
        final future = controller.applyReferralCode('CODE1');

        // Assert — intermediate loading state
        expect(controller.state.isLoading, true);
        expect(controller.state.error, isNull);
        expect(controller.state.isSuccess, false);

        // Complete the use case
        completer.complete(const Success(null));
        await future;

        // Assert — final state
        expect(controller.state.isLoading, false);
        expect(controller.state.isSuccess, true);
      });

      test('should set success state and code when apply succeeds', () async {
        // Arrange
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Success(null));
        when(() => mockApplyReferralCode('MOOZE123'))
            .thenAnswer((_) async => const Success(null));

        final controller = createController();
        await Future<void>.delayed(Duration.zero);

        // Act
        final result = await controller.applyReferralCode('MOOZE123');

        // Assert
        expect(result, true);
        expect(controller.state.isLoading, false);
        expect(controller.state.isSuccess, true);
        expect(controller.state.existingReferralCode, 'MOOZE123');
        expect(controller.state.error, isNull);
      });

      test('should set error state when apply fails', () async {
        // Arrange
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Success(null));
        when(() => mockApplyReferralCode('BAD'))
            .thenAnswer((_) async => const Failure('Invalid code'));

        final controller = createController();
        await Future<void>.delayed(Duration.zero);

        // Act
        final result = await controller.applyReferralCode('BAD');

        // Assert
        expect(result, false);
        expect(controller.state.isLoading, false);
        expect(controller.state.error, 'Invalid code');
        expect(controller.state.isSuccess, false);
      });

      test('should return true on success and false on failure', () async {
        // Arrange
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Success(null));
        when(() => mockApplyReferralCode('GOOD'))
            .thenAnswer((_) async => const Success(null));
        when(() => mockApplyReferralCode('BAD'))
            .thenAnswer((_) async => const Failure('Error'));

        final controller = createController();
        await Future<void>.delayed(Duration.zero);

        // Act & Assert
        expect(await controller.applyReferralCode('GOOD'), true);
        expect(await controller.applyReferralCode('BAD'), false);
      });
    });

    group('clearError', () {
      test('should clear the error from state', () async {
        // Arrange
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Success(null));
        when(() => mockApplyReferralCode('BAD'))
            .thenAnswer((_) async => const Failure('Error'));

        final controller = createController();
        await Future<void>.delayed(Duration.zero);
        await controller.applyReferralCode('BAD');
        expect(controller.state.error, 'Error');

        // Act
        controller.clearError();

        // Assert
        expect(controller.state.error, isNull);
      });
    });

    group('resetState', () {
      test('should clear error and success flags', () async {
        // Arrange
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Success(null));
        when(() => mockApplyReferralCode('CODE'))
            .thenAnswer((_) async => const Success(null));

        final controller = createController();
        await Future<void>.delayed(Duration.zero);
        await controller.applyReferralCode('CODE');
        expect(controller.state.isSuccess, true);

        // Act
        controller.resetState();

        // Assert
        expect(controller.state.error, isNull);
        expect(controller.state.isSuccess, false);
      });
    });

    group('refreshUser', () {
      test('should re-check existing referral code', () async {
        // Arrange
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Success(null));

        final controller = createController();
        await Future<void>.delayed(Duration.zero);

        // Change the mock to return a code for the refresh call
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Success('NEW_CODE'));

        // Act
        await controller.refreshUser();

        // Assert
        expect(controller.state.existingReferralCode, 'NEW_CODE');
        // Called twice: once in init, once in refreshUser
        verify(() => mockGetExistingReferral()).called(2);
      });
    });
  });
}
