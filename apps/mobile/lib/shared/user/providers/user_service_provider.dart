import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/network/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services.dart';
import '../services/user_data_cache_service.dart';
import '../services/user_id_storage_service.dart';
import '../services/wallet_levels_cache_service.dart';
import '../services/user_level_storage_service.dart';
import '../services/mock_user_service.dart';

const String baseUrl = String.fromEnvironment(
  'BACKEND_API_URL',
  defaultValue: 'https://api.mooze.app',
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

/// The user id that the API gave, kept for the support screen.
final userIdStorageServiceProvider = Provider<UserIdStorageService>((ref) {
  return UserIdStorageService(ref.watch(sharedPreferencesProvider));
});

/// The last answer of `/users/me`, kept for the level screen and the limits.
final userDataCacheServiceProvider = Provider<UserDataCacheService>((ref) {
  return UserDataCacheService(ref.watch(sharedPreferencesProvider));
});

/// The last table of the level limits.
final walletLevelsCacheServiceProvider = Provider<WalletLevelsCacheService>((
  ref,
) {
  return WalletLevelsCacheService(ref.watch(sharedPreferencesProvider));
});

final userServiceProvider = Provider<UserService>((ref) {
  // return MockUserService();
  final authHttpClient = ref.watch(authenticatedClientProvider);
  final levelStorageService = ref.watch(userLevelStorageServiceProvider);
  return UserServiceImpl(
    authHttpClient,
    levelStorageService,
    idStorage: ref.watch(userIdStorageServiceProvider),
    userCache: ref.watch(userDataCacheServiceProvider),
  );
});
