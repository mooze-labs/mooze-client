import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/features/referral_input/domain/repositories/referral_repository.dart';
import 'package:mooze_mobile/features/referral_input/domain/usecases/apply_referral_code_usecase.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class MockReferralRepository extends Mock implements ReferralRepository {}

void main() {
  late MockReferralRepository mockRepository;
  late ApplyReferralCodeUseCase useCase;

  setUp(() {
    mockRepository = MockReferralRepository();
    useCase = ApplyReferralCodeUseCase(mockRepository);
  });

  group('ApplyReferralCodeUseCase', () {
    group('success cases', () {
      test('should return Success when code is valid and applied', () async {
        // Arrange
        when(() => mockRepository.validateReferralCode('MOOZE123'))
            .thenAnswer((_) async => const Success(true));
        when(() => mockRepository.applyReferralCode('MOOZE123'))
            .thenAnswer((_) async => const Success(null));

        // Act
        final result = await useCase('MOOZE123');

        // Assert
        expect(result.isSuccess, true);
        verify(() => mockRepository.validateReferralCode('MOOZE123')).called(1);
        verify(() => mockRepository.applyReferralCode('MOOZE123')).called(1);
      });
    });

    group('validation failures', () {
      test('should return Failure when code is empty', () async {
        // Act
        final result = await useCase('');

        // Assert
        expect(result.isFailure, true);
        expect(result.error, 'Código não pode ser vazio');
        verifyNever(() => mockRepository.validateReferralCode(any()));
        verifyNever(() => mockRepository.applyReferralCode(any()));
      });

      test('should return Failure when validation returns false', () async {
        // Arrange
        when(() => mockRepository.validateReferralCode('INVALID'))
            .thenAnswer((_) async => const Success(false));

        // Act
        final result = await useCase('INVALID');

        // Assert
        expect(result.isFailure, true);
        expect(result.error, 'Código inválido. Verifique e tente novamente.');
        verify(() => mockRepository.validateReferralCode('INVALID')).called(1);
        verifyNever(() => mockRepository.applyReferralCode(any()));
      });

      test('should return Failure when validation request fails', () async {
        // Arrange
        when(() => mockRepository.validateReferralCode('CODE1'))
            .thenAnswer((_) async => const Failure('Network error'));

        // Act
        final result = await useCase('CODE1');

        // Assert
        expect(result.isFailure, true);
        expect(result.error, 'Código inválido. Verifique e tente novamente.');
        verifyNever(() => mockRepository.applyReferralCode(any()));
      });
    });

    group('application failures', () {
      test('should return Failure when apply request fails', () async {
        // Arrange
        when(() => mockRepository.validateReferralCode('MOOZE123'))
            .thenAnswer((_) async => const Success(true));
        when(() => mockRepository.applyReferralCode('MOOZE123'))
            .thenAnswer((_) async => const Failure('Server error'));

        // Act
        final result = await useCase('MOOZE123');

        // Assert
        expect(result.isFailure, true);
        expect(
          result.error,
          'Erro ao adicionar código. Tente novamente.',
        );
        verify(() => mockRepository.validateReferralCode('MOOZE123')).called(1);
        verify(() => mockRepository.applyReferralCode('MOOZE123')).called(1);
      });
    });

    group('call order', () {
      test('should validate before applying', () async {
        // Arrange
        final callOrder = <String>[];

        when(() => mockRepository.validateReferralCode('CODE1'))
            .thenAnswer((_) async {
          callOrder.add('validate');
          return const Success(true);
        });
        when(() => mockRepository.applyReferralCode('CODE1'))
            .thenAnswer((_) async {
          callOrder.add('apply');
          return const Success(null);
        });

        // Act
        await useCase('CODE1');

        // Assert
        expect(callOrder, ['validate', 'apply']);
      });

      test('should not call apply when validation fails', () async {
        // Arrange
        when(() => mockRepository.validateReferralCode('BAD'))
            .thenAnswer((_) async => const Failure('Error'));

        // Act
        await useCase('BAD');

        // Assert
        verify(() => mockRepository.validateReferralCode('BAD')).called(1);
        verifyNever(() => mockRepository.applyReferralCode(any()));
      });
    });
  });
}
