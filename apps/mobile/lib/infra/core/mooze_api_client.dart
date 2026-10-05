import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

/// Default Mooze backend URL. The core uses the same default.
const String moozeApiDefaultBaseUrl = 'https://api.mooze.app';

/// The Mooze backend URL of this build (`BACKEND_API_URL`).
const String moozeApiBaseUrl = String.fromEnvironment(
  'BACKEND_API_URL',
  defaultValue: moozeApiDefaultBaseUrl,
);

/// Sends Mooze backend requests through `MoozeCore.apiRequest`.
///
/// The core attaches the session token, refreshes it once on 401/403 and
/// adds the device metrics. Token logic exists only in the core.
class MoozeApiClient {
  MoozeApiClient(this._core);

  final Future<MoozeCore> Function() _core;

  /// Sends one request. [path] is relative to the backend base URL and
  /// can hold a query string. [jsonBody] is JSON text.
  ///
  /// Returns non-2xx statuses. Throws [CoreError] on transport errors and
  /// on a failed session refresh (`CoreErrorKind.session`).
  Future<ApiResponseDto> request(
    HttpMethodDto method,
    String path, {
    String? jsonBody,
  }) async {
    final core = await _core();
    return core.apiRequest(method: method, path: path, jsonBody: jsonBody);
  }

  /// A [Dio] for the Mooze backend that sends every request through this
  /// client. Callers keep their Dio code: paths, bodies, JSON parsing and
  /// [DioException]s on non-2xx statuses do not change.
  Dio dio({String baseUrl = moozeApiBaseUrl}) {
    return Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = MoozeApiHttpAdapter(this, baseUrl: baseUrl);
  }
}

/// Dio transport over [MoozeApiClient].
///
/// Accepts only URLs under [baseUrl], so the core never sends the session
/// token to another host.
class MoozeApiHttpAdapter implements HttpClientAdapter {
  MoozeApiHttpAdapter(this._client, {required String baseUrl})
      : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;

  final MoozeApiClient _client;
  final String _baseUrl;

  static const _jsonHeaders = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };
  static const _textHeaders = {
    Headers.contentTypeHeader: [Headers.textPlainContentType],
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = _relativePath(options);
    final method = _method(options.method);
    final body = requestStream == null ? null : await _readBody(requestStream);

    final ApiResponseDto response;
    try {
      response = await _client.request(
        method,
        path,
        jsonBody: (body == null || body.isEmpty) ? null : body,
      );
    } on CoreError catch (e) {
      throw _mapError(options, e);
    }
    return ResponseBody.fromString(
      response.body,
      response.status,
      headers: _looksLikeJson(response.body) ? _jsonHeaders : _textHeaders,
    );
  }

  @override
  void close({bool force = false}) {}

  String _relativePath(RequestOptions options) {
    final url = options.uri.toString();
    if (!url.startsWith(_baseUrl)) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: ArgumentError('MoozeApiHttpAdapter: $url is not under $_baseUrl'),
      );
    }
    final rest = url.substring(_baseUrl.length);
    return rest.startsWith('/') ? rest : '/$rest';
  }

  static HttpMethodDto _method(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return HttpMethodDto.get_;
      case 'POST':
        return HttpMethodDto.post;
      case 'PUT':
        return HttpMethodDto.put;
      case 'PATCH':
        return HttpMethodDto.patch;
      case 'DELETE':
        return HttpMethodDto.delete;
    }
    throw UnsupportedError('MoozeApiHttpAdapter: method $method');
  }

  static Future<String> _readBody(Stream<Uint8List> stream) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    return utf8.decode(builder.takeBytes());
  }

  static bool _looksLikeJson(String body) {
    final t = body.trimLeft();
    return t.startsWith('{') || t.startsWith('[');
  }

  /// A failed session refresh becomes the 401 that the legacy interceptor
  /// passed on. Transport errors keep their Dio types.
  static DioException _mapError(RequestOptions options, CoreError e) {
    switch (e.kind) {
      case CoreErrorKind.session:
        return DioException.badResponse(
          statusCode: 401,
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 401,
            data: e.message,
          ),
        );
      case CoreErrorKind.timeout:
        return DioException.connectionTimeout(
          timeout: options.connectTimeout ?? Duration.zero,
          requestOptions: options,
          error: e,
        );
      case CoreErrorKind.network:
        return DioException.connectionError(
          requestOptions: options,
          reason: e.message,
          error: e,
        );
      default:
        return DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: e,
          message: e.message,
        );
    }
  }
}
