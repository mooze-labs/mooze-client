import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:safe_device/safe_device.dart';

import '../../authentication/services.dart';
import '../../authentication/services/device_info_service.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._sessionManager,
    this._dio, {
    DeviceIdService? deviceIdService,
    DeviceInfoService? deviceInfoService,
  })  : _deviceIdService = deviceIdService ?? DeviceIdService(),
        _deviceInfoService = deviceInfoService ?? DeviceInfoService();

  final SessionManagerService _sessionManager;
  final Dio _dio;
  final DeviceIdService _deviceIdService;
  final DeviceInfoService _deviceInfoService;

  static const _unauthenticatedPaths = <String>[
    '/auth/challenge',
    '/auth/sign',
    '/auth/sign_challenge',
    '/auth/refresh',
    '/auth/login',
  ];

  static const _retryMarker = 'x-mooze-auth-retry';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await _attachMetrics(options);

    if (_shouldSkipAuth(options.path)) {
      handler.next(options);
      return;
    }

    final safe = await _isSafeDevice();
    if (!safe) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }

    final result = await _sessionManager.getSession().run();
    result.fold(
      (_) {
        options.headers.remove('Authorization');
        handler.next(options);
      },
      (session) {
        options.headers['Authorization'] = 'Bearer ${session.jwt}';
        handler.next(options);
      },
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (status != 401 && status != 403) {
      handler.next(err);
      return;
    }
    if (_shouldSkipAuth(path)) {
      handler.next(err);
      return;
    }
    if (err.requestOptions.extra[_retryMarker] == true) {
      handler.next(err);
      return;
    }

    final refreshed = await _sessionManager.forceRefresh().run();
    await refreshed.fold(
      (_) async => handler.next(err),
      (session) async {
        final retryOptions = err.requestOptions
          ..headers['Authorization'] = 'Bearer ${session.jwt}'
          ..extra[_retryMarker] = true;
        try {
          final response = await _dio.fetch(retryOptions);
          handler.resolve(response);
        } on DioException catch (e) {
          handler.next(e);
        } catch (_) {
          handler.next(err);
        }
      },
    );
  }

  bool _shouldSkipAuth(String path) =>
      _unauthenticatedPaths.any(path.contains);

  Future<bool> _isSafeDevice() async {
    if (!kReleaseMode) return true;
    final task = TaskEither<String, bool>.tryCatch(
      () async => SafeDevice.isSafeDevice,
      (error, _) => error.toString(),
    );
    final result = await task.run();
    return result.getOrElse((_) => false);
  }

  Future<void> _attachMetrics(RequestOptions options) async {
    final metrics = await _collectMetrics();
    if (metrics.isEmpty) return;

    final data = options.data;
    if (data is Map<String, dynamic>) {
      options.data = {...data, 'metrics': metrics};
    } else if (data == null) {
      options.data = {'metrics': metrics};
    }
  }

  Future<Map<String, dynamic>> _collectMetrics() async {
    try {
      final deviceId = await _deviceIdService.getDeviceId();
      final deviceInfo = await _deviceInfoService.getDeviceInfo();
      return {
        'device_id': deviceId,
        'battery_level': deviceInfo.batteryLevel,
        'screen_brightness': deviceInfo.screenBrightness,
        'boot_time': deviceInfo.bootTime?.toIso8601String(),
      };
    } catch (_) {
      return const {};
    }
  }
}
