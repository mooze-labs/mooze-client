import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/network/providers.dart';
import '../services.dart';

const String baseUrl = String.fromEnvironment(
  'BACKEND_API_URL',
  defaultValue: 'https://api.mooze.app/v1',
);

final userServiceProvider = Provider<UserService>((ref) {
  final authHttpClient = ref.watch(authenticatedClientProvider(baseUrl));
  return UserServiceImpl(authHttpClient);
});
