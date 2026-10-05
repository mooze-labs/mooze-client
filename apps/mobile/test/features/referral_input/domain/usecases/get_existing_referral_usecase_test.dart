import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/features/referral_input/domain/repositories/referral_repository.dart';
import 'package:mooze_mobile/features/referral_input/domain/usecases/get_existing_referral_usecase.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class MockReferralRepository extends Mock implements ReferralRepository {}

void main() {
  late MockReferralRepository mockRepository;
  late GetExistingReferralUseCase useCase;

  setUp(() {
    mockRepository = MockReferralRepository();
    useCase = GetExistingReferralUseCase(mockRepository);
  });

  group('GetExistingReferralUseCase', () {
    group('success cases', () {
      test('should return referral code when user has one applied', () async {
        // Arrange
        when(() => mockRepository.getExistingReferral())
            .thenAnswer((_) async => const Success('MOOZE123'));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, 'MOOZE123');
        verify(() => mockRepository.getExistingReferral()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should return null when user has no referral code', () async {
        // Arrange
        when(() => mockRepository.getExistingReferral())
            .thenAnswer((_) async => const Success(null));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNull);
        verify(() => mockRepository.getExistingReferral()).called(1);
      });
    });

    group('failure cases', () {
      test('should return failure when repository fails', () async {
        // Arrange
        when(() => mockRepository.getExistingReferral())
            .thenAnswer((_) async => const Failure('Erro ao buscar código'));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, true);
        expect(result.error, 'Erro ao buscar código');
        verify(() => mockRepository.getExistingReferral()).called(1);
      });
    });
  });
}
