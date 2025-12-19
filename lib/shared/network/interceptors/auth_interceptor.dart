import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:safe_device/safe_device.dart';

import '../../authentication/models.dart';
import '../../authentication/services.dart';
import '../../authentication/services/remote_auth_service_impl.dart';
import '../../key_management/store/mnemonic_store_impl.dart';
import '../../key_management/store/key_store_impl.dart';

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

    // Check if device is safe
    final isSafe =
        kReleaseMode
            ? TaskEither<String, bool>.tryCatch(
              () async => await SafeDevice.isSafeDevice,
              (error, stackTrace) => error.toString(),
            )
            : TaskEither<String, bool>.right(true);

    final isSafeResult = await isSafe.run();

    await isSafeResult.fold(
      (error) async {
        // Device safety check failed, proceed without auth
        options.headers.remove('Authorization');
        handler.next(options);
      },
      (safe) async {
        if (!safe) {
          // Device is not safe, proceed without auth
          options.headers.remove('Authorization');
          handler.next(options);
          return;
        }

        // Device is safe, get a valid session (automatically refreshes if needed)
        final sessionResult = await _sessionManager.getSession().run();

        sessionResult.fold(
          (error) {
            // If we can't get a valid session, proceed without auth
            // The API will return 401 and the app can handle accordingly
            // Note: This can happen if no mnemonic is available yet
            // Make sure to remove any existing Authorization header
            options.headers.remove('Authorization');
            handler.next(options);
          },
          (session) {
            // Add JWT to Authorization header
            options.headers['Authorization'] = 'Bearer ${session.jwt}';
            handler.next(options);
          },
        );
      },
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized responses
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
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
        // Try to get mnemonic and create a new session
        final remoteAuthServiceResult = await _getRemoteAuthService().run();

        await remoteAuthServiceResult.fold(
          (error) async {
            _isRefreshing = false;
            await _sessionManager.deleteSession().run();
            handler.next(err);
          },
          (remoteAuthService) async {
            final newSessionResult =
                await _createNewSession(remoteAuthService).run();

            await newSessionResult.fold(
              (error) async {
                _isRefreshing = false;
                await _sessionManager.deleteSession().run();
                handler.next(err);
              },
              (newSession) async {
                await _sessionManager.saveSession(newSession).run();

                _isRefreshing = false;
                _refreshAttempts = 0; // Reset counter on success

                // Retry the original request with new token
                final options = err.requestOptions;
                options.headers['Authorization'] = 'Bearer ${newSession.jwt}';

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

  /// Get RemoteAuthService by loading mnemonic from storage
  TaskEither<String, RemoteAuthenticationService> _getRemoteAuthService() {
    return TaskEither.tryCatch(() async {
      final keyStore = KeyStoreImpl();
      final mnemonicStore = MnemonicStoreImpl(keyStore: keyStore);
      final mnemonicResult = await mnemonicStore.getMnemonic().run();

      return mnemonicResult.fold(
        (error) => throw Exception('Failed to get mnemonic: $error'),
        (mnemonicOption) => mnemonicOption.fold(
          () => throw Exception('Mnemonic not found'),
          (mnemonic) => RemoteAuthServiceImpl.withEcdsaClient(mnemonic),
        ),
      );
    }, (error, stackTrace) => error.toString());
  }

  /// Create a new session through complete authentication flow
  TaskEither<String, Session> _createNewSession(
    RemoteAuthenticationService remoteAuthService,
  ) {
    return remoteAuthService.requestLoginChallenge().flatMap((challenge) {
      return remoteAuthService.signChallenge(challenge);
    });
  }
}
