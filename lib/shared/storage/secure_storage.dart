import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized secure storage configuration
class SecureStorageProvider {
  SecureStorageProvider._();

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  static FlutterSecureStorage get instance => const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );
}
