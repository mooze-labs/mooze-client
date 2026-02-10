import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unique_identifier/unique_identifier.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service responsible for generating and managing the unique Device ID
///
/// This ID is used for fraud prevention and:
/// - Persists between app sessions
/// - Persists even after uninstall/reinstall (on iOS/Android via Keychain/Keystore)
/// - Is unique per device
class DeviceIdService {
  static const String _storageKey = 'device_id';
  static const Uuid _uuidGenerator = Uuid();

  final FlutterSecureStorage _secureStorage;

  DeviceIdService({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              encryptedSharedPreferences: true,
              // Use AES 256 for enhanced security
              resetOnError: false,
            ),
            iOptions: IOSOptions(
              // Accessible after first unlock and persists in Keychain
              accessibility: KeychainAccessibility.first_unlock_this_device,
              // Synchronize with iCloud Keychain (optional, helps maintain same ID)
              synchronizable: false,
            ),
          );

  /// Gets the unique Device ID
  ///
  /// Strategy:
  /// 1. Check if an ID already exists in SecureStorage
  /// 2. If not, try to get a hardware identifier
  /// 3. If unable, generate a random UUID
  /// 4. Save the ID in SecureStorage for reuse
  Future<String> getDeviceId() async {
    try {
      // 1. Check if an ID already exists
      String? savedDeviceId = await _secureStorage.read(key: _storageKey);

      if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
        debugPrint(
          '[DeviceIdService] Device ID retrieved from storage: ${savedDeviceId.substring(0, 8)}...',
        );
        return savedDeviceId;
      }

      // 2. Try to get a hardware-based identifier
      String? hardwareBasedId = await _getHardwareBasedId();

      if (hardwareBasedId != null && hardwareBasedId.isNotEmpty) {
        // Save for reuse
        await _secureStorage.write(key: _storageKey, value: hardwareBasedId);
        debugPrint(
          '[DeviceIdService] Device ID generated based on hardware: ${hardwareBasedId.substring(0, 8)}...',
        );
        return hardwareBasedId;
      }

      // 3. Fallback: Generate random UUID
      final newDeviceId = _uuidGenerator.v4();
      await _secureStorage.write(key: _storageKey, value: newDeviceId);
      debugPrint(
        '[DeviceIdService] UUID Device ID generated: ${newDeviceId.substring(0, 8)}...',
      );
      return newDeviceId;
    } catch (e, stackTrace) {
      debugPrint('[DeviceIdService] Error getting device ID: $e');
      debugPrint('[DeviceIdService] StackTrace: $stackTrace');

      // Final fallback: UUID without persistence (not ideal, but ensures functionality)
      return _uuidGenerator.v4();
    }
  }

  /// Gets an identifier based on hardware characteristics
  ///
  /// This approach tries to create a fingerprint based on:
  /// - Android: androidId (unique per device and app after factory reset)
  /// - iOS: identifierForVendor (unique per vendor, persists between reinstalls)
  ///
  /// Limitations:
  /// - Android: androidId changes after factory reset
  /// - iOS: identifierForVendor changes if all vendor apps are uninstalled
  Future<String?> _getHardwareBasedId() async {
    try {
      // Try to get unique ID from native platform
      String? uniqueId = await UniqueIdentifier.serial;

      if (uniqueId != null && uniqueId.isNotEmpty && uniqueId != 'unknown') {
        // Create hash to standardize the format
        return _hashId(uniqueId);
      }

      // Fallback: use device_info_plus
      final deviceInfo = DeviceInfoPlugin();

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        // androidId is unique per device/app (changes after factory reset)
        if (androidInfo.id.isNotEmpty) {
          return _hashId(androidInfo.id);
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // identifierForVendor persists between reinstalls (except if all vendor apps are removed)
        if (iosInfo.identifierForVendor != null) {
          return _hashId(iosInfo.identifierForVendor!);
        }
      }

      return null;
    } catch (e) {
      debugPrint('[DeviceIdService] Error getting hardware ID: $e');
      return null;
    }
  }

  /// Creates a SHA-256 hash of the ID to standardize the format
  String _hashId(String id) {
    final bytes = utf8.encode(id);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Clears the saved Device ID (useful for testing or manual reset)
  Future<void> clearDeviceId() async {
    try {
      await _secureStorage.delete(key: _storageKey);
      debugPrint('[DeviceIdService] Device ID removed from storage');
    } catch (e) {
      debugPrint('[DeviceIdService] Error clearing device ID: $e');
    }
  }

  /// Checks if a saved Device ID exists
  Future<bool> hasDeviceId() async {
    try {
      final savedId = await _secureStorage.read(key: _storageKey);
      return savedId != null && savedId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
