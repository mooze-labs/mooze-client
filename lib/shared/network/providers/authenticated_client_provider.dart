import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_interceptor_provider.dart';

final authenticatedClientProvider = Provider.family<Dio, String>((
  ref,
  baseUrl,
) {
  final authInterceptor = ref.watch(authInterceptorProvider(baseUrl));
  final dio = Dio(BaseOptions(baseUrl: baseUrl))
    ..interceptors.add(authInterceptor);

  return dio;
});
