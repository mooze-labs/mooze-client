import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/network/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services.dart';
import '../services/user_level_storage_service.dart';

const String baseUrl = String.fromEnvironment(
  'BACKEND_API_URL',
  defaultValue: 'https://10.0.2.2:3000',
);

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final userLevelStorageServiceProvider = Provider<UserLevelStorageService>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserLevelStorageService(prefs);
});

final userServiceProvider = Provider<UserService>((ref) {
  final authHttpClient = ref.watch(authenticatedClientProvider);
  final levelStorageService = ref.watch(userLevelStorageServiceProvider);
  return UserServiceImpl(authHttpClient, levelStorageService);
});
