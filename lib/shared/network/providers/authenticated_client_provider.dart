import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_interceptor_provider.dart';

const _apiBaseUrl = String.fromEnvironment("BACKEND_API_URL", defaultValue: "https://api.mooze.app/v1/");

final authenticatedClientProvider = Provider<Dio>((
  ref,
) {
  final authInterceptor = ref.watch(authInterceptorProvider(_apiBaseUrl));
  final dio = Dio(BaseOptions(baseUrl: _apiBaseUrl))
    ..interceptors.add(authInterceptor);

  return dio;
});
