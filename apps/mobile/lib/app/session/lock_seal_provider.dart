import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_scene.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';

/// The face of the seal that covers the app, when it is hidden or locked:
/// the biometric of the device when the user unlocks with it. Null for a
/// PIN alone, whose cover keeps the padlock.
///
/// Read ahead of time: the privacy shield paints in the first frame of a
/// change of the app lifecycle, so it shows a value already here. A change
/// of the preference invalidates [isBiometricEnabledProvider], and this
/// follows.
final lockSealKindProvider = FutureProvider<BiometricKind?>((ref) async {
  final enabled = await ref.watch(isBiometricEnabledProvider.future);
  if (!enabled) return null;
  final capabilities = await ref
      .read(biometricServiceProvider)
      .capabilities()
      .run();
  return capabilities.hasBiometrics ? BiometricKind.of(capabilities) : null;
});
