import 'package:dio/dio.dart';

import '../services.dart';

/// Dio interceptor that automatically handles JWT authentication and token refresh
class AuthInterceptor extends Interceptor {
  final SessionManagerService _sessionManager;
  final Dio _dio;

  AuthInterceptor(this._sessionManager, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip authentication for auth endpoints
    if (_shouldSkipAuth(options.path)) {
      handler.next(options);
      return;
    }

    // Get a valid session (automatically refreshes if needed)
    final sessionResult = await _sessionManager.getSession().run();

    sessionResult.fold(
      (error) {
        // If we can't get a valid session, proceed without auth
        // The API will return 401 and the app can handle accordingly
        handler.next(options);
      },
      (session) {
        // Add JWT to Authorization header
        options.headers['Authorization'] = 'Bearer ${session.jwt}';
        handler.next(options);
      },
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized responses
    if (err.response?.statusCode == 401) {
      // Try to refresh the session
      final refreshResult = await _sessionManager.refreshSession().run();

      refreshResult.fold(
        (error) {
          // Refresh failed, pass through the original error
          handler.next(err);
        },
        (_) async {
          // Refresh successful, retry the original request
          final sessionResult = await _sessionManager.getSession().run();

          sessionResult.fold((error) => handler.next(err), (session) async {
            // Update the authorization header and retry
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer ${session.jwt}';

            try {
              final response = await _dio.fetch(options);
              handler.resolve(response);
            } catch (e) {
              handler.next(err);
            }
          });
        },
      );
    } else {
      handler.next(err);
    }
  }

  /// Check if authentication should be skipped for this path
  bool _shouldSkipAuth(String path) {
    const unauthenticatedPaths = [
      '/auth/login',
      '/auth/sign_challenge',
      '/auth/refresh',
    ];

    return unauthenticatedPaths.any((unauthPath) => path.contains(unauthPath));
  }
}
