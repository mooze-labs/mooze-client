import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/authentication/providers.dart';

import '../interceptors/auth_interceptor.dart';

final authInterceptorProvider = ProviderFamily<AuthInterceptor, String>((
  ref,
  url,
) {
  final sessionManagerService = ref.watch(sessionManagerServiceProvider);

  return AuthInterceptor(sessionManagerService, Dio(BaseOptions(baseUrl: url)));
});
