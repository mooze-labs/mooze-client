import 'dart:convert';
import 'dart:io' show HttpDate, HttpException;

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/data/pix_api_log.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_repository.dart';
import 'package:mooze_mobile/infra/core/mooze_api_client.dart'
    show moozeApiBaseUrl;
import 'package:mooze_mobile/shared/authentication/services/session_manager_service.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' show depixAssetId;

/// [PixWithdrawalRepository] over `POST /withdraw` and `GET /withdraw/status`.
///
/// The contract comes from the OpenAPI document of the Mooze Engine:
/// - The routes live on the backend of `BACKEND_API_URL` (`api.mooze.app`).
/// - `Authorization: Bearer <jwt>` carries the session JWT of mooze-core.
/// - The create body has exactly `pix_key`, `payout_amount_in_cents`,
///   `tax_id` and `refund_address`. The API rejects unknown fields.
/// - Success is `200` with `{data, error: null}`.
/// - A failure is `{data: null, error: <text>}`, or a body that is not JSON.
///
/// NOTE: The requests do not use `MoozeApiClient`. That client adds `metrics`
/// to JSON bodies, which `POST /withdraw` rejects.
class ApiPixWithdrawalRepository implements PixWithdrawalRepository {
  ApiPixWithdrawalRepository({
    required Dio dio,
    required SessionManagerService session,
    DateTime Function()? now,
    void Function(String message)? log,
  }) : _dio = dio,
       _session = session,
       _now = now ?? DateTime.now,
       _log = log ?? _ignore;

  /// Lowest payout of `NewWithdrawRequest`, in BRL cents.
  static const int minPayoutInCents = 200;

  /// Highest payout of `NewWithdrawRequest`, in BRL cents.
  static const int maxPayoutInCents = 600000;

  /// Most IDs that one status request accepts.
  static const int maxStatusIds = 50;

  static const String _createPath = '/withdraw';
  static const String _statusPath = '/withdraw/status';

  final Dio _dio;
  final SessionManagerService _session;
  final DateTime Function() _now;

  /// Receives one line per failure. The screens show a generic text, so the
  /// HTTP status and the server error reach the logs only.
  final void Function(String message) _log;

  static void _ignore(String _) {}

  /// A [Dio] for [baseUrl] that returns every status as text, so the
  /// repository reads JSON, empty and HTML bodies the same way.
  ///
  /// The backend creates the withdrawal at the provider before it answers, so
  /// the receive timeout is longer than the connect timeout.
  static Dio createDio({String baseUrl = moozeApiBaseUrl}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
        listFormat: ListFormat.multi,
        headers: const {'Accept': 'application/json'},
      ),
    );
  }

  @override
  TaskEither<PixHubFailure, PixWithdrawal> create({
    required String pixKey,
    required int payoutAmountInCents,
    required String taxId,
    required String refundAddress,
  }) {
    return TaskEither(() async {
      if (payoutAmountInCents < minPayoutInCents ||
          payoutAmountInCents > maxPayoutInCents) {
        return const Left(PixHubFailure(PixHubErrorCode.amountOutOfBounds));
      }

      final body = jsonEncode(<String, Object>{
        'pix_key': pixKey.trim(),
        'payout_amount_in_cents': payoutAmountInCents,
        'tax_id': taxId,
        'refund_address': refundAddress,
      });

      final response = await _sendWithRefresh(
        'create',
        (jwt) => _dio.post<String>(
          _createPath,
          data: body,
          options: Options(
            contentType: Headers.jsonContentType,
            headers: {'Authorization': 'Bearer $jwt'},
          ),
        ),
      );
      return response.flatMap(
        (r) => _parseCreated(r, requestedPayout: payoutAmountInCents),
      );
    });
  }

  @override
  TaskEither<PixHubFailure, List<PixWithdrawalDetails>> statuses(
    List<String> ids,
  ) {
    return TaskEither(() async {
      if (ids.isEmpty) return const Right([]);
      if (ids.length > maxStatusIds) {
        return const Left(
          PixHubFailure(
            PixHubErrorCode.unknown,
            rawMessage: 'too many withdrawal ids',
          ),
        );
      }

      final response = await _sendWithRefresh(
        'status',
        (jwt) => _dio.get<String>(
          _statusPath,
          // Repeated keys: `?ids=a&ids=b`, as the contract requires.
          queryParameters: {'ids': ids},
          options: Options(headers: {'Authorization': 'Bearer $jwt'}),
        ),
      );
      return response.flatMap(_parseStatuses);
    });
  }

  /// Sends the request with the session JWT. A 401 gets one forced refresh
  /// and the same request again, as the core client does.
  ///
  /// The retry is safe for `POST /withdraw`: the JWT middleware answers 401
  /// before the handler runs, so the first request created nothing.
  Future<Either<PixHubFailure, Response<String>>> _sendWithRefresh(
    String operation,
    Future<Response<String>> Function(String jwt) send,
  ) async {
    final first = await _sendOnce(operation, send, forceRefresh: false);
    return first.fold(
      (failure) async => Left(failure),
      (response) async => response.statusCode == 401
          ? await _sendOnce(operation, send, forceRefresh: true)
          : Right(response),
    );
  }

  Future<Either<PixHubFailure, Response<String>>> _sendOnce(
    String operation,
    Future<Response<String>> Function(String jwt) send, {
    required bool forceRefresh,
  }) async {
    final token =
        await (forceRefresh ? _session.forceRefresh() : _session.getSession())
            .run();

    return token.fold(
      (message) async {
        _log('$operation: no session token');
        return Left(
          PixHubFailure(
            PixHubErrorCode.sessionUnavailable,
            rawMessage: message,
          ),
        );
      },
      (session) async {
        try {
          return Right(await send(session.jwt));
        } on DioException catch (e) {
          _log('$operation: transport ${e.type.name}');
          return Left(
            PixHubFailure(_transportCode(e), rawMessage: e.message ?? '$e'),
          );
        }
      },
    );
  }

  Either<PixHubFailure, PixWithdrawal> _parseCreated(
    Response<String> response, {
    required int requestedPayout,
  }) {
    final status = response.statusCode ?? 0;
    final json = _decodeObject(response.data);

    if (status == 200) {
      final withdrawal = _withdrawalFromJson(
        json?['data'],
        requestedPayout: requestedPayout,
        serverNow: _serverDate(response),
      );
      final refused = withdrawal.getLeft().toNullable();
      if (refused != null) {
        _log('create: refused answer, ${refused.rawMessage}');
      }
      return withdrawal;
    }
    return Left(_httpFailure(response, json, isCreate: true));
  }

  Either<PixHubFailure, List<PixWithdrawalDetails>> _parseStatuses(
    Response<String> response,
  ) {
    final status = response.statusCode ?? 0;
    final json = _decodeObject(response.data);

    if (status == 200) {
      final data = json?['data'];
      if (data is! List) {
        return Left(
          PixHubFailure(
            PixHubErrorCode.invalidResponse,
            rawMessage: 'http $status without a status list',
          ),
        );
      }
      // An item the app cannot read is left out, like an unknown ID.
      return Right(data.map(_detailsFromJson).nonNulls.toList());
    }
    return Left(_httpFailure(response, json, isCreate: false));
  }

  PixHubFailure _httpFailure(
    Response<String> response,
    Map<String, dynamic>? json, {
    required bool isCreate,
  }) {
    final status = response.statusCode ?? 0;
    final error = json?['error'];
    final text = error is String ? error : _snippet(response.data);
    _log(
      '${isCreate ? 'create' : 'status'}: http $status, '
      '${json == null ? 'not json' : 'json'}, '
      'server ${response.headers.value('server') ?? '-'}: ${redactForLog(text)}',
    );
    return PixHubFailure(
      _errorCode(status, isJson: json != null, isCreate: isCreate),
      rawMessage: 'http $status $text',
    );
  }

  /// Maps an HTTP failure to a hub error code.
  ///
  /// The statuses and their meaning come from the OpenAPI description of
  /// `POST /withdraw`.
  static PixHubErrorCode _errorCode(
    int status, {
    required bool isJson,
    required bool isCreate,
  }) {
    switch (status) {
      case 400:
        return PixHubErrorCode.invalidRequest;
      case 401:
        return PixHubErrorCode.sessionUnavailable;
      // A 403 without the JSON envelope comes from the edge, for example a
      // Cloudflare challenge page, not from the API.
      case 403:
        return isJson
            ? PixHubErrorCode.limitExceeded
            : PixHubErrorCode.serviceUnavailable;
      case 404:
        return PixHubErrorCode.serviceUnavailable;
      case 422:
        return PixHubErrorCode.providerRefused;
      case 429:
        return PixHubErrorCode.rateLimited;
      // The contract states that a 503 on create means an unknown outcome.
      case 503:
        return isCreate
            ? PixHubErrorCode.outcomeUnknown
            : PixHubErrorCode.serviceUnavailable;
    }
    if (status >= 500) return PixHubErrorCode.serviceUnavailable;
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

  /// Reads a `WithdrawCreated` and checks it against the request.
  ///
  /// Any mismatch stops the flow before the wallet funds anything: a wrong
  /// asset, a payout that differs from the request, a negative fee, or a DePix
  /// amount that does not match the BRL amount.
  Either<PixHubFailure, PixWithdrawal> _withdrawalFromJson(
    Object? data, {
    required int requestedPayout,
    required DateTime? serverNow,
  }) {
    PixHubFailure invalid(String reason) =>
        PixHubFailure(PixHubErrorCode.invalidResponse, rawMessage: reason);
    PixHubFailure mismatch(String reason) =>
        PixHubFailure(PixHubErrorCode.quoteMismatch, rawMessage: reason);

    if (data is! Map<String, dynamic>) return Left(invalid('no data'));
    final id = data['id'];
    final providerId = data['provider_id'];
    final address = data['deposit_address'];
    final asset = data['asset'];
    final depositCents = data['deposit_amount_in_cents'];
    final depositSats = data['deposit_amount_sats'];
    final payoutCents = data['payout_amount_in_cents'];
    final expiresAt = _date(data['expires_at']);

    if (id is! String || id.isEmpty) return Left(invalid('no id'));
    if (providerId is! String) return Left(invalid('no provider_id'));
    if (address is! String || !_bareAddress.hasMatch(address)) {
      return Left(invalid('deposit_address is not a bare address'));
    }
    if (depositCents is! int || depositSats is! int || payoutCents is! int) {
      return Left(invalid('amounts are not integers'));
    }
    if (expiresAt == null) return Left(invalid('no expires_at'));

    if (asset != depixAssetId) return Left(mismatch('asset is not DePix'));
    if (payoutCents != requestedPayout) {
      return Left(mismatch('payout differs from the request'));
    }
    if (depositCents < payoutCents) {
      return Left(mismatch('deposit is lower than the payout'));
    }
    if (depositSats != depositCents * PixWithdrawal.depixUnitsPerCent) {
      return Left(mismatch('deposit sats do not match deposit cents'));
    }

    // The remaining time comes from the server clock. The device clock only
    // counts it down, so a wrong device clock does not move the deadline.
    final deadline = serverNow == null
        ? expiresAt
        : _now().add(expiresAt.difference(serverNow));

    return Right(
      PixWithdrawal(
        id: id,
        providerId: providerId,
        depositAddress: address,
        assetId: asset as String,
        depositAmountInCents: depositCents,
        depositAmountSats: depositSats,
        payoutAmountInCents: payoutCents,
        expiresAt: expiresAt,
        fundingDeadline: deadline,
      ),
    );
  }

  /// Reads a `WithdrawDetails`. Returns null without an id or a creation date.
  static PixWithdrawalDetails? _detailsFromJson(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final id = data['id'];
    final createdAt = _date(data['created_at']);
    if (id is! String || id.isEmpty || createdAt == null) return null;

    final refund = data['refund'];
    return PixWithdrawalDetails(
      id: id,
      status: PixWithdrawalStatus.parse(data['status']),
      createdAt: createdAt,
      depositAmountInCents: _int(data['deposit_amount_in_cents']),
      payoutAmountInCents: _int(data['payout_amount_in_cents']),
      expiresAt: _date(data['expires_at']),
      blockchainTxid: _string(data['blockchain_txid']),
      receiptUrl: _string(data['receipt_url']),
      receiverName: _string(data['receiver_name']),
      receiverTaxNumber: _string(data['receiver_tax_number']),
      transferDate: _date(data['transfer_date']),
      centralBankId: _string(data['central_bank_id']),
      refund: refund is Map<String, dynamic>
          ? PixWithdrawalRefund(
              reason: _string(refund['reason']),
              txId: _string(refund['txId']),
              feeInCents: _int(refund['feeInCents']),
              netAmountInCents: _int(refund['netAmountInCents']),
            )
          : null,
    );
  }

  /// Bech32 and base58 characters only: no URI scheme, no query, no spaces.
  static final RegExp _bareAddress = RegExp(r'^[A-Za-z0-9]{26,}$');

  static DateTime? _serverDate(Response<String> response) {
    final value = response.headers.value('date');
    if (value == null) return null;
    try {
      return HttpDate.parse(value);
    } on HttpException {
      return null;
    }
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static int? _int(Object? value) => value is int ? value : null;

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

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
