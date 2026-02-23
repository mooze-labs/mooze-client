import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mooze_mobile/shared/authentication/services/device_id_service.dart';

@GenerateMocks([FlutterSecureStorage])
import 'device_id_service_test.mocks.dart';

void main() {
  late DeviceIdService deviceIdService;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    deviceIdService = DeviceIdService(secureStorage: mockStorage);
  });

  group('DeviceIdService', () {
    test('should generate a new device ID when no saved ID exists', () async {
      // Arrange
      when(mockStorage.read(key: 'device_id')).thenAnswer((_) async => null);
      when(
        mockStorage.write(key: 'device_id', value: anyNamed('value')),
      ).thenAnswer((_) async => {});

      // Act
      final deviceId = await deviceIdService.getDeviceId();

      // Assert
      expect(deviceId, isNotEmpty);
      expect(deviceId.length, greaterThan(20));
      verify(mockStorage.read(key: 'device_id')).called(1);
      verify(
        mockStorage.write(key: 'device_id', value: anyNamed('value')),
      ).called(1);
    });

    test('should reuse existing device ID', () async {
      // Arrange
      const savedDeviceId = 'existing-device-id-12345';
      when(
        mockStorage.read(key: 'device_id'),
      ).thenAnswer((_) async => savedDeviceId);

      // Act
      final deviceId = await deviceIdService.getDeviceId();

      // Assert
      expect(deviceId, equals(savedDeviceId));
      verify(mockStorage.read(key: 'device_id')).called(1);
      verifyNever(
        mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
      );
    });

    test('should return the same ID on multiple calls', () async {
      // Arrange
      when(mockStorage.read(key: 'device_id')).thenAnswer((_) async => null);
      when(
        mockStorage.write(key: 'device_id', value: anyNamed('value')),
      ).thenAnswer((_) async => {});

      // Act
      final deviceId1 = await deviceIdService.getDeviceId();

      // Simulate that the ID is now saved
      when(
        mockStorage.read(key: 'device_id'),
      ).thenAnswer((_) async => deviceId1);

      final deviceId2 = await deviceIdService.getDeviceId();

      // Assert
      expect(deviceId1, equals(deviceId2));
    });

    test('should generate valid UUID on fallback', () async {
      // Arrange
      when(mockStorage.read(key: 'device_id')).thenAnswer((_) async => null);
      when(
        mockStorage.write(key: 'device_id', value: anyNamed('value')),
      ).thenAnswer((_) async => {});

      // Act
      final deviceId = await deviceIdService.getDeviceId();

      // Assert
      // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      // Can be a UUID or a hash (64 hex characters)
      final isUuid = uuidPattern.hasMatch(deviceId);
      final isHash =
          deviceId.length == 64 &&
          RegExp(r'^[0-9a-f]+$', caseSensitive: false).hasMatch(deviceId);

      expect(isUuid || isHash, isTrue);
    });

    test('should clear device ID correctly', () async {
      // Arrange
      when(mockStorage.delete(key: 'device_id')).thenAnswer((_) async => {});

      // Act
      await deviceIdService.clearDeviceId();

      // Assert
      verify(mockStorage.delete(key: 'device_id')).called(1);
    });

    test('hasDeviceId should return true when ID exists', () async {
      // Arrange
      when(
        mockStorage.read(key: 'device_id'),
      ).thenAnswer((_) async => 'some-device-id');

      // Act
      final hasId = await deviceIdService.hasDeviceId();

      // Assert
      expect(hasId, isTrue);
    });

    test('hasDeviceId should return false when no ID exists', () async {
      // Arrange
      when(mockStorage.read(key: 'device_id')).thenAnswer((_) async => null);

      // Act
      final hasId = await deviceIdService.hasDeviceId();

      // Assert
      expect(hasId, isFalse);
    });

    test('hasDeviceId should return false when ID is empty', () async {
      // Arrange
      when(mockStorage.read(key: 'device_id')).thenAnswer((_) async => '');

      // Act
      final hasId = await deviceIdService.hasDeviceId();

      // Assert
      expect(hasId, isFalse);
    });

    test('should generate device ID even on storage error', () async {
      // Arrange
      when(
        mockStorage.read(key: 'device_id'),
      ).thenThrow(Exception('Storage error'));
      when(
        mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
      ).thenThrow(Exception('Storage error'));

      // Act
      final deviceId = await deviceIdService.getDeviceId();

      // Assert
      // Should return a UUID even without being able to save
      expect(deviceId, isNotEmpty);
    });

    test('clearDeviceId should not throw exception on error', () async {
      // Arrange
      when(
        mockStorage.delete(key: 'device_id'),
      ).thenThrow(Exception('Storage error'));

      // Act & Assert
      expect(
        () async => await deviceIdService.clearDeviceId(),
        returnsNormally,
      );
    });
  });
}
