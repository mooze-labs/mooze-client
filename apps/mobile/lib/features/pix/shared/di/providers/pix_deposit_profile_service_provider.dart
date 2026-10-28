import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/data/services/pix_deposit_profile_service.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

final pixDepositProfileServiceProvider = Provider<PixDepositProfileService>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PixDepositProfileService(prefs);
});
