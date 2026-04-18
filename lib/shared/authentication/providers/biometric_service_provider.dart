import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/biometric_service.dart';
import '../services/biometric_service_impl.dart';

/// Provides the [BiometricService] singleton used across the app.
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricServiceImpl();
});

/// Whether the device has biometric / device-credential hardware available.
///
/// Cached per session — hardware capability does not change at runtime.
final isBiometricAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(biometricServiceProvider);
  return service.isAvailable().run();
});

/// Whether the user has opted in to biometric authentication.
///
/// Invalidate this provider after calling [BiometricService.setEnabled] so
/// all listeners (settings toggle, verify-PIN screen) see the new value.
final isBiometricEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(biometricServiceProvider);
  return service.isEnabled().run();
});
