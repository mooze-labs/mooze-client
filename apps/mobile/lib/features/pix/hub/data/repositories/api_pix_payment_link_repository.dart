import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/data/pix_api_log.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link_amount.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_payment_link_repository.dart';
import 'package:mooze_mobile/shared/authentication/services/session_manager_service.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Base URL of the payment-link API (`PAYMENT_LINK_API_URL`).
///
/// NOTE: The payment-link routes live on `pay.mooze.app`. `api.mooze.app`
/// answers 404 to them.
const String paymentLinkApiBaseUrl = String.fromEnvironment(
  'PAYMENT_LINK_API_URL',
  defaultValue: 'https://pay.mooze.app',
);

/// [PixPaymentLinkRepository] over `POST /payment-links`.
///
/// The contract comes from the OpenAPI document of the Mooze Engine:
/// - `Authorization: Bearer <jwt>` carries the session JWT of mooze-core.
/// - `Idempotency-Key` is required.
/// - The body has `asset`, `destination_address`, `usage_policy` and
///   `amount_policy`. The API rejects unknown fields.
/// - Success is `201` with `{data: OwnerPaymentLink, error: null}`.
/// - A failure is `{data: null, error: <code>}`, or a body that is not JSON.
///
/// NOTE: The request does not use `MoozeApiClient`. That client reaches
/// `api.mooze.app` only, takes no headers and adds `metrics` to JSON bodies,
/// which this endpoint rejects.
class ApiPixPaymentLinkRepository implements PixPaymentLinkRepository {
  ApiPixPaymentLinkRepository({
    required Dio dio,
    required SessionManagerService session,
    DateTime Function()? now,
    void Function(String message)? log,
  }) : _dio = dio,
       _session = session,
       _now = now ?? DateTime.now,
       _log = log ?? _ignore;

  /// Assets the API accepts: L-BTC and DePix.
  static const Set<Asset> acceptedAssets = {Asset.lbtc, Asset.depix};

  static const String _path = '/payment-links';

  final Dio _dio;
  final SessionManagerService _session;
  final DateTime Function() _now;

  /// Receives one line per HTTP answer and per failure, for the
  /// [paymentLinkLogKey] logs. It never gets the JWT.
  final void Function(String message) _log;

  static void _ignore(String _) {}

  /// A [Dio] for [baseUrl] that returns every status as text, so the
  /// repository reads JSON, empty and HTML bodies the same way.
  static Dio createDio({String baseUrl = paymentLinkApiBaseUrl}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
        headers: const {'Accept': 'application/json'},
      ),
    );
  }

  @override
  TaskEither<PixHubFailure, PixPaymentLink> createFixedAmountLink({
    required int amountInCents,
    required Asset asset,
    required String destinationAddress,
    required bool singleUse,
    required String idempotencyKey,
  }) {
    return TaskEither(() async {
      if (!FixedPaymentLinkAmount(amountInCents).isWithinBounds) {
        return const Left(PixHubFailure(PixHubErrorCode.amountOutOfBounds));
      }
      if (!acceptedAssets.contains(asset)) {
        return Left(
          PixHubFailure(
            PixHubErrorCode.unknown,
            rawMessage: 'asset ${asset.name} is not accepted',
          ),
        );
      }

      _log(
        'request POST ${_dio.options.baseUrl}$_path '
        'amount=$amountInCents asset=${EnumName(asset).name} '
        'usage=${singleUse ? 'single_use' : 'reusable'} '
        'destination=${shortAddress(destinationAddress)} '
        'idempotency_key=$idempotencyKey',
      );

      final body = <String, Object>{
        'asset': asset.id,
        'destination_address': destinationAddress,
        'usage_policy': singleUse ? 'single_use' : 'reusable',
        'amount_policy': {'type': 'fixed', 'amount_in_cents': amountInCents},
      };

      final first = await _post(body, idempotencyKey, forceRefresh: false);
      // The server rejected the JWT: refresh it once and send the same
      // request again, as the core client does.
      final response = await first.fold(
        (failure) async => Left<PixHubFailure, Response<String>>(failure),
        (response) async => response.statusCode == 401
            ? await _post(body, idempotencyKey, forceRefresh: true)
            : Right<PixHubFailure, Response<String>>(response),
      );
      return response.flatMap(_parse);
    });
  }

  Future<Either<PixHubFailure, Response<String>>> _post(
    Map<String, Object> body,
    String idempotencyKey, {
    required bool forceRefresh,
  }) async {
    final token =
        await (forceRefresh ? _session.forceRefresh() : _session.getSession())
            .run();

    final attempt = forceRefresh ? 2 : 1;
    return token.fold(
      (message) async {
        _log('session failed attempt=$attempt: ${logSnippet(message)}');
        return Left(
          PixHubFailure(
            PixHubErrorCode.sessionUnavailable,
            rawMessage: message,
          ),
        );
      },
      (session) async {
        try {
          final response = await _dio.post<String>(
            _path,
            data: jsonEncode(body),
            options: Options(
              contentType: Headers.jsonContentType,
              headers: {
                'Authorization': 'Bearer ${session.jwt}',
                'Idempotency-Key': idempotencyKey,
              },
            ),
          );
          _logResponse(response, attempt);
          return Right(response);
        } on DioException catch (e) {
          _log(
            'transport failed attempt=$attempt type=${e.type.name}: '
            '${logSnippet(e.message ?? '$e')}',
          );
          return Left(
            PixHubFailure(_transportCode(e), rawMessage: e.message ?? '$e'),
          );
        }
      },
    );
  }

  /// One line per answer. A failure also gets the headers that tell an edge
  /// rejection (Cloudflare) from an API error, and a masked body snippet.
  void _logResponse(Response<String> response, int attempt) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      _log('response http $status attempt=$attempt');
      return;
    }
    final headers = response.headers;
    final json = _decodeObject(response.data);
    final error = json?['error'];
    _log(
      'response http $status attempt=$attempt '
      'json=${json != null} '
      'content-type=${headers.value(Headers.contentTypeHeader) ?? '-'} '
      'server=${headers.value('server') ?? '-'} '
      'cf-ray=${headers.value('cf-ray') ?? '-'} '
      'cf-mitigated=${headers.value('cf-mitigated') ?? '-'} '
      'error=${error is String ? error : '-'} '
      'body="${logSnippet(response.data)}"',
    );
  }

  Either<PixHubFailure, PixPaymentLink> _parse(Response<String> response) {
    final status = response.statusCode ?? 0;
    final json = _decodeObject(response.data);

    if (status >= 200 && status < 300) {
      final link = _linkFromJson(json?['data']);
      if (link == null) {
        _log(
          'invalid answer http $status: no link id or URL, '
          'body="${logSnippet(response.data)}"',
        );
        return Left(
          PixHubFailure(
            PixHubErrorCode.invalidResponse,
            rawMessage: 'http $status without a valid link',
          ),
        );
      }
      return Right(link);
    }

    final error = json?['error'];
    final code = error is String ? error : null;
    return Left(
      PixHubFailure(
        _errorCode(status, code, isJson: json != null),
        rawMessage: 'http $status ${code ?? _snippet(response.data)}',
      ),
    );
  }

  /// Maps an HTTP failure to a hub error code.
  ///
  /// The domain codes come from the OpenAPI description of the endpoint.
  static PixHubErrorCode _errorCode(
    int status,
    String? code, {
    required bool isJson,
  }) {
    switch (code) {
      case 'AMOUNT_OUT_OF_BOUNDS':
        return PixHubErrorCode.amountOutOfBounds;
      case 'INELIGIBLE':
        return PixHubErrorCode.notEligible;
      case 'RATE_LIMITED':
        return PixHubErrorCode.rateLimited;
      case 'UNAUTHORIZED':
        return PixHubErrorCode.sessionUnavailable;
      case 'MAINTENANCE':
      case 'UNAVAILABLE':
      case 'PROVIDER_UNCERTAIN':
        return PixHubErrorCode.serviceUnavailable;
    }
    if (status == 401) return PixHubErrorCode.sessionUnavailable;
    if (status == 429) return PixHubErrorCode.rateLimited;
    // A 403 without the JSON envelope comes from the edge, for example a
    // Cloudflare challenge page, not from the API.
    if (status == 403) {
      return isJson
          ? PixHubErrorCode.notEligible
          : PixHubErrorCode.serviceUnavailable;
    }
    // The API answers 404 when the payment-link routes are not configured.
    if (status == 404 || status >= 500) {
      return PixHubErrorCode.serviceUnavailable;
    }
    return PixHubErrorCode.unknown;
  }

  static PixHubErrorCode _transportCode(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => PixHubErrorCode.network,
      _ => PixHubErrorCode.unknown,
    };
  }

  /// Reads an `OwnerPaymentLink`. Returns null without an id or an http(s) URL.
  PixPaymentLink? _linkFromJson(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final id = data['id'];
    final url = data['url'];
    if (id is! String || id.isEmpty || url is! String) return null;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !(uri.isScheme('https') || uri.isScheme('http')) ||
        uri.host.isEmpty) {
      return null;
    }

    final amount = data['amount'];
    final amountInCents =
        amount is Map<String, dynamic> && amount['type'] == 'fixed'
        ? (amount['amount_in_cents'] as num?)?.toInt()
        : null;

    final now = _now();
    final expiresAt = _date(data['expires_at']);
    final expired =
        _date(data['revoked_at']) != null ||
        (expiresAt != null && expiresAt.isBefore(now));

    return PixPaymentLink(
      id: id,
      url: url,
      // The API has no reference field.
      reference: '',
      amountInCents: amountInCents,
      status: data['consumed'] == true
          ? PixPaymentLinkStatus.paid
          : expired
          ? PixPaymentLinkStatus.expired
          : PixPaymentLinkStatus.pending,
      createdAt: _date(data['created_at']) ?? now,
      singleUse: data['usage'] == 'single_use',
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static Map<String, dynamic>? _decodeObject(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    try {
      final value = jsonDecode(text);
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  static String _snippet(String? text) {
    final value = (text ?? '').trim();
    return value.length <= 80 ? value : '${value.substring(0, 80)}…';
  }
}
