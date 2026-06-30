import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/features/referral_input/infra/datasources/referral_datasource.dart';
import 'package:mooze_mobile/features/referral_input/infra/repositories/referral_repository_impl.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class MockReferralDataSource extends Mock implements ReferralDataSource {}

void main() {
  late MockReferralDataSource mockDataSource;
  late ReferralRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockReferralDataSource();
    repository = ReferralRepositoryImpl(mockDataSource);
  });

  group('ReferralRepositoryImpl', () {
    group('getExistingReferral', () {
      test('should return Success with code when datasource succeeds',
          () async {
        // Arrange
        when(() => mockDataSource.getExistingReferral())
            .thenAnswer((_) async => const Success('MOOZE123'));

        // Act
        final result = await repository.getExistingReferral();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, 'MOOZE123');
        verify(() => mockDataSource.getExistingReferral()).called(1);
      });

      test('should return Success with null when no code exists', () async {
        // Arrange
        when(() => mockDataSource.getExistingReferral())
            .thenAnswer((_) async => const Success(null));

        // Act
        final result = await repository.getExistingReferral();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNull);
      });

      test('should return Failure when datasource returns Failure', () async {
        // Arrange
        when(() => mockDataSource.getExistingReferral())
            .thenAnswer((_) async => const Failure('API error'));

        // Act
        final result = await repository.getExistingReferral();

        // Assert
        expect(result.isFailure, true);
        expect(result.error, 'API error');
      });

      test('should return Failure when datasource throws exception', () async {
        // Arrange
        when(() => mockDataSource.getExistingReferral())
            .thenThrow(Exception('Unexpected error'));

        // Act
        final result = await repository.getExistingReferral();

        // Assert
        expect(result.isFailure, true);
        expect(result.error, contains('Erro ao buscar código de indicação'));
      });
    });

    group('validateReferralCode', () {
      test('should return Success(true) when code is valid', () async {
        // Arrange
        when(() => mockDataSource.validateReferralCode('VALID'))
            .thenAnswer((_) async => const Success(true));

        // Act
        final result = await repository.validateReferralCode('VALID');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, true);
        verify(() => mockDataSource.validateReferralCode('VALID')).called(1);
      });

      test('should return Success(false) when code is invalid', () async {
        // Arrange
        when(() => mockDataSource.validateReferralCode('INVALID'))
            .thenAnswer((_) async => const Success(false));

        // Act
        final result = await repository.validateReferralCode('INVALID');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, false);
      });

      test('should return Failure when datasource returns Failure', () async {
        // Arrange
        when(() => mockDataSource.validateReferralCode('CODE'))
            .thenAnswer((_) async => const Failure('Network error'));

        // Act
        final result = await repository.validateReferralCode('CODE');

        // Assert
        expect(result.isFailure, true);
        expect(result.error, 'Network error');
      });

      test('should return Failure when datasource throws exception', () async {
        // Arrange
        when(() => mockDataSource.validateReferralCode('CODE'))
            .thenThrow(Exception('Connection timeout'));

        // Act
        final result = await repository.validateReferralCode('CODE');

        // Assert
        expect(result.isFailure, true);
        expect(result.error, contains('Erro ao validar código'));
      });
    });

    group('applyReferralCode', () {
      test('should return Success when code is applied', () async {
        // Arrange
        when(() => mockDataSource.applyReferralCode('MOOZE123'))
            .thenAnswer((_) async => const Success(null));

        // Act
        final result = await repository.applyReferralCode('MOOZE123');

        // Assert
        expect(result.isSuccess, true);
        verify(() => mockDataSource.applyReferralCode('MOOZE123')).called(1);
      });

      test('should return Failure when datasource returns Failure', () async {
        // Arrange
        when(() => mockDataSource.applyReferralCode('CODE'))
            .thenAnswer((_) async => const Failure('Server error'));

        // Act
        final result = await repository.applyReferralCode('CODE');

        // Assert
        expect(result.isFailure, true);
        expect(result.error, 'Server error');
      });

      test('should return Failure when datasource throws exception', () async {
        // Arrange
        when(() => mockDataSource.applyReferralCode('CODE'))
            .thenThrow(Exception('Timeout'));

        // Act
        final result = await repository.applyReferralCode('CODE');

        // Assert
        expect(result.isFailure, true);
        expect(result.error, contains('Erro ao aplicar código'));
      });
    });
  });
}
