import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/network/providers.dart';
import '../services.dart';

const String baseUrl = String.fromEnvironment(
  'BACKEND_API_URL',
  defaultValue: 'https://10.0.2.2:3000',
);

final userServiceProvider = Provider<UserService>((ref) {
  final authHttpClient = ref.watch(authenticatedClientProvider);
  return UserServiceImpl(authHttpClient);
});
