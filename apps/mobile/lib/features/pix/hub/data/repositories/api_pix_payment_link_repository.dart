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

/// [PixPaymentLinkRepository] over `POST /payment-links`,
/// `GET /payment-links` and `POST /payment-links/{id}/revoke`.
///
/// The contract comes from the OpenAPI document of the Mooze Engine:
/// - `Authorization: Bearer <jwt>` carries the session JWT of mooze-core.
/// - The create request requires `Idempotency-Key`.
/// - The create body has `asset`, `destination_address`, `usage_policy` and
///   `amount_policy`. The API rejects unknown fields.
/// - The list takes `limit` (at most 100) and the cursor of the last item,
///   and answers `{items, next_cursor}`, newest first.
/// - Success is `{data: ..., error: null}`.
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

  /// Largest page that `GET /payment-links` returns.
  static const int _pageSize = 100;

  /// Most pages that one list reads.
  static const int _maxPages = 10;

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
    return createLink(
      amountInCents: amountInCents,
      asset: asset,
      destinationAddress: destinationAddress,
      singleUse: singleUse,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  TaskEither<PixHubFailure, PixPaymentLink> createLink({
    int? amountInCents,
    required Asset asset,
    required String destinationAddress,
    required bool singleUse,
    required String idempotencyKey,
  }) {
    return TaskEither(() async {
      if (amountInCents != null &&
          !FixedPaymentLinkAmount(amountInCents).isWithinBounds) {
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
        'amount=${amountInCents ?? 'variable'} '
        'asset=${EnumName(asset).name} '
        'usage=${singleUse ? 'single_use' : 'reusable'} '
        'destination=${shortAddress(destinationAddress)} '
        'idempotency_key=$idempotencyKey',
      );

      final body = jsonEncode(<String, Object>{
        'asset': asset.id,
        'destination_address': destinationAddress,
        'usage_policy': singleUse ? 'single_use' : 'reusable',
        'amount_policy': amountInCents == null
            ? {'type': 'variable'}
            : {'type': 'fixed', 'amount_in_cents': amountInCents},
      });

      final response = await _sendWithRefresh(
        (jwt) => _dio.post<String>(
          _path,
          data: body,
          options: Options(
            contentType: Headers.jsonContentType,
            headers: {
              'Authorization': 'Bearer $jwt',
              'Idempotency-Key': idempotencyKey,
            },
          ),
        ),
      );
      return response.flatMap(_parseLink);
    });
  }

  @override
  TaskEither<PixHubFailure, List<PixPaymentLink>> listLinks() {
    return TaskEither(() async {
      final links = <PixPaymentLink>[];
      Map<String, String>? cursor;
      // A full page may have a next one. The page cap stops a server that
      // keeps answering full pages.
      for (var page = 0; page < _maxPages; page++) {
        _log('request GET ${_dio.options.baseUrl}$_path page=$page');
        final response = await _sendWithRefresh(
          (jwt) => _dio.get<String>(
            _path,
            queryParameters: {'limit': '$_pageSize', ...?cursor},
            options: Options(headers: {'Authorization': 'Bearer $jwt'}),
          ),
        );
        final parsed = response.flatMap(_parsePage);
        if (parsed.isLeft()) return parsed.map((_) => links);
        final (items, next) = parsed.getRight().toNullable()!;
        links.addAll(items);
        if (items.length < _pageSize || next == null) break;
        cursor = next;
      }
      return Right(links);
    });
  }

  @override
  TaskEither<PixHubFailure, Unit> revokeLink(String id) {
    return TaskEither(() async {
      final path = '$_path/${Uri.encodeComponent(id)}/revoke';
      _log('request POST ${_dio.options.baseUrl}$path');
      final response = await _sendWithRefresh(
        (jwt) => _dio.post<String>(
          path,
          options: Options(headers: {'Authorization': 'Bearer $jwt'}),
        ),
      );
      return response.flatMap((r) {
        final status = r.statusCode ?? 0;
        return status >= 200 && status < 300
            ? const Right(unit)
            : Left(_httpFailure(r));
      });
    });
  }

  /// Sends the request with the session JWT. A 401 gets one forced refresh
  /// and the same request again, as the core client does.
  ///
  /// The retry is safe for the create request: the JWT middleware answers
  /// 401 before the handler runs, and the idempotency key covers the rest.
  Future<Either<PixHubFailure, Response<String>>> _sendWithRefresh(
    Future<Response<String>> Function(String jwt) send,
  ) async {
    final first = await _sendOnce(send, attempt: 1);
    return first.fold(
      (failure) async => Left(failure),
      (response) async => response.statusCode == 401
          ? await _sendOnce(send, attempt: 2)
          : Right(response),
    );
  }

  Future<Either<PixHubFailure, Response<String>>> _sendOnce(
    Future<Response<String>> Function(String jwt) send, {
    required int attempt,
  }) async {
    final token =
        await (attempt > 1 ? _session.forceRefresh() : _session.getSession())
            .run();

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
          final response = await send(session.jwt);
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

  Either<PixHubFailure, PixPaymentLink> _parseLink(Response<String> response) {
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) return Left(_httpFailure(response));

    final link = _linkFromJson(_decodeObject(response.data)?['data']);
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

  /// Reads a `PaymentLinkPage`: the links and the cursor of the next page.
  ///
  /// An item the app cannot read is left out, so one bad item does not hide
  /// the others.
  Either<PixHubFailure, (List<PixPaymentLink>, Map<String, String>?)>
  _parsePage(Response<String> response) {
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) return Left(_httpFailure(response));

    final data = _decodeObject(response.data)?['data'];
    final items = data is Map<String, dynamic> ? data['items'] : null;
    if (items is! List) {
      _log('invalid answer http $status: no link list');
      return Left(
        PixHubFailure(
          PixHubErrorCode.invalidResponse,
          rawMessage: 'http $status without a link list',
        ),
      );
    }

    final next = (data as Map<String, dynamic>)['next_cursor'];
    final createdAt = next is Map<String, dynamic> ? next['created_at'] : null;
    final id = next is Map<String, dynamic> ? next['id'] : null;
    return Right((
      items.map(_linkFromJson).nonNulls.toList(),
      createdAt is String && id is String
          ? {'before_created_at': createdAt, 'before_id': id}
          : null,
    ));
  }

  PixHubFailure _httpFailure(Response<String> response) {
    final status = response.statusCode ?? 0;
    final json = _decodeObject(response.data);
    final error = json?['error'];
    final code = error is String ? error : null;
    return PixHubFailure(
      _errorCode(status, code, isJson: json != null),
      rawMessage: 'http $status ${code ?? _snippet(response.data)}',
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

    return PixPaymentLink(
      id: id,
      url: url,
      // The API has no reference field. The app keeps it on the device.
      reference: '',
      amountInCents: amountInCents,
      asset: _assetFromId(data['asset']),
      // A paid link stays paid after a revoke or its expiry.
      status: data['consumed'] == true
          ? PixPaymentLinkStatus.paid
          : _date(data['revoked_at']) != null
          ? PixPaymentLinkStatus.revoked
          : expiresAt != null && expiresAt.isBefore(now)
          ? PixPaymentLinkStatus.expired
          : PixPaymentLinkStatus.pending,
      createdAt: _date(data['created_at']) ?? now,
      singleUse: data['usage'] == 'single_use',
    );
  }

  /// The asset of an id, among the [acceptedAssets]. [Asset.fromId] would
  /// read an unknown id as Bitcoin.
  static Asset? _assetFromId(Object? id) {
    for (final asset in acceptedAssets) {
      if (asset.id == id) return asset;
    }
    return null;
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
