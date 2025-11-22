import 'package:dio/dio.dart';

import '../../authentication/services.dart';

/// Dio interceptor that automatically handles JWT authentication and token refresh
class AuthInterceptor extends Interceptor {
  final SessionManagerService _sessionManager;
  final Dio _dio;
  bool _isRefreshing = false;
  int _refreshAttempts = 0;
  static const int _maxRefreshAttempts = 3;

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
        // Note: This can happen if no mnemonic is available yet
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
      // Check if we've exceeded max refresh attempts
      if (_refreshAttempts >= _maxRefreshAttempts) {
        _refreshAttempts = 0;
        _isRefreshing = false;
        // Clear invalid session
        await _sessionManager.deleteSession().run();
        handler.next(err);
        return;
      }

      // If already refreshing, wait for it to complete
      if (_isRefreshing) {
        // Add this request to pending queue
        await Future.delayed(Duration(milliseconds: 100));

        // Try to get the refreshed session and retry
        final sessionResult = await _sessionManager.getSession().run();
        await sessionResult.fold(
          (error) async {
            handler.next(err);
          },
          (session) async {
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer ${session.jwt}';

            try {
              final response = await _dio.fetch(options);
              handler.resolve(response);
            } catch (e) {
              handler.next(err);
            }
          },
        );
        return;
      }

      // Start refresh process
      _isRefreshing = true;
      _refreshAttempts++;

      try {
        // Get the current session
        final currentSessionResult = await _sessionManager.getSession().run();

        await currentSessionResult.fold(
          (error) async {
            _isRefreshing = false;
            handler.next(err);
          },
          (currentSession) async {
            // Force refresh the session regardless of local expiration status
            final refreshResult =
                await _sessionManager.refreshSession(currentSession).run();

            await refreshResult.fold(
              (error) async {
                _isRefreshing = false;

                // Se refresh token não existe (404), limpar sessão inválida
                if (error.contains('REFRESH_TOKEN_NOT_FOUND') ||
                    error.contains('Refresh token inválido')) {
                  await _sessionManager.deleteSession().run();
                }

                handler.next(err);
              },
              (refreshedSession) async {
                // Save the refreshed session
                await _sessionManager.saveSession(refreshedSession).run();

                _isRefreshing = false;
                _refreshAttempts = 0; // Reset counter on success

                // Retry the original request with new token
                final options = err.requestOptions;
                options.headers['Authorization'] =
                    'Bearer ${refreshedSession.jwt}';

                try {
                  final response = await _dio.fetch(options);
                  handler.resolve(response);
                } catch (e) {
                  handler.next(err);
                }
              },
            );
          },
        );
      } catch (e) {
        _isRefreshing = false;
        handler.next(err);
      }
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
