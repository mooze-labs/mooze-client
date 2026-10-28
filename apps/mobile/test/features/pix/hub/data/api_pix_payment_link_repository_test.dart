import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/data/repositories/api_pix_payment_link_repository.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/shared/authentication/models/session.dart';
import 'package:mooze_mobile/shared/authentication/services/session_manager_service.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Answers each request with the next queued response.
class _QueueAdapter implements HttpClientAdapter {
  final List<ResponseBody Function(RequestOptions options)> _queue;
  final List<RequestOptions> requests = [];
  final List<String> bodies = [];

  _QueueAdapter(this._queue);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final bytes = requestStream == null
        ? <int>[]
        : await requestStream.expand((chunk) => chunk).toList();
    bodies.add(utf8.decode(bytes));
    return _queue.removeAt(0)(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Session manager that hands out `jwt-1`, then `jwt-2` after a refresh.
class _FakeSession implements SessionManagerService {
  int getCalls = 0;
  int refreshCalls = 0;
  String? failure;

  @override
  TaskEither<String, Session> getSession() {
    getCalls++;
    return failure == null
        ? TaskEither.right(Session(jwt: 'jwt-1', refreshToken: 'rt'))
        : TaskEither.left(failure!);
  }

  @override
  TaskEither<String, Session> forceRefresh() {
    refreshCalls++;
    return TaskEither.right(Session(jwt: 'jwt-2', refreshToken: 'rt'));
  }

  @override
  TaskEither<String, Session> refreshSession(Session session) => forceRefresh();

  @override
  TaskEither<String, Unit> saveSession(Session session) =>
      TaskEither.right(unit);

  @override
  TaskEither<String, Unit> deleteSession() => TaskEither.right(unit);

  @override
  TaskEither<String, Unit> resetIdentity() => TaskEither.right(unit);
}

ResponseBody Function(RequestOptions) _json(int status, Object body) =>
    (_) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody Function(RequestOptions) _text(int status, String body) =>
    (_) => ResponseBody.fromString(body, status);

const _created = {
  'data': {
    'id': '8f3c2a51-6d0e-4b8a-9a52-2f1d9c7e4b10',
    'url': 'https://pay.mooze.app/pay/tok_abc123',
    'asset': depixAssetId,
    'destination_address': 'lq1qqdest',
    'usage': 'single_use',
    'amount': {'type': 'fixed', 'amount_in_cents': 4590},
    'expires_at': null,
    'revoked_at': null,
    'consumed': false,
    'reserved': false,
    'created_at': '2026-10-21T13:00:00Z',
  },
  'error': null,
};

void main() {
  late _FakeSession session;

  ApiPixPaymentLinkRepository repositoryWith(_QueueAdapter adapter) {
    final dio = ApiPixPaymentLinkRepository.createDio(
      baseUrl: 'https://pay.test',
    )..httpClientAdapter = adapter;
    return ApiPixPaymentLinkRepository(
      dio: dio,
      session: session,
      now: () => DateTime.utc(2026, 10, 21, 14),
    );
  }

  Future<Either<PixHubFailure, PixPaymentLink>> create(
    ApiPixPaymentLinkRepository repository, {
    int amountInCents = 4590,
    Asset asset = Asset.depix,
  }) {
    return repository
        .createFixedAmountLink(
          amountInCents: amountInCents,
          asset: asset,
          destinationAddress: 'lq1qqdest',
          singleUse: true,
          idempotencyKey: 'key-1',
        )
        .run();
  }

  PixHubErrorCode failureCode(Either<PixHubFailure, PixPaymentLink> result) =>
      result.getLeft().toNullable()!.code;

  setUp(() => session = _FakeSession());

  test('creates a link with the request of the OpenAPI contract', () async {
    final adapter = _QueueAdapter([_json(201, _created)]);

    final result = await create(repositoryWith(adapter));

    final link = result.getRight().toNullable()!;
    expect(link.id, '8f3c2a51-6d0e-4b8a-9a52-2f1d9c7e4b10');
    expect(link.url, 'https://pay.mooze.app/pay/tok_abc123');
    expect(link.amountInCents, 4590);
    expect(link.singleUse, isTrue);
    expect(link.status, PixPaymentLinkStatus.pending);
    expect(link.createdAt, DateTime.utc(2026, 10, 21, 13));

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.toString(), 'https://pay.test/payment-links');
    expect(request.headers['Authorization'], 'Bearer jwt-1');
    expect(request.headers['Idempotency-Key'], 'key-1');
    expect(request.contentType, startsWith('application/json'));
    // The API rejects unknown fields, so the body has exactly these keys.
    expect(jsonDecode(adapter.bodies.single), {
      'asset': depixAssetId,
      'destination_address': 'lq1qqdest',
      'usage_policy': 'single_use',
      'amount_policy': {'type': 'fixed', 'amount_in_cents': 4590},
    });
  });

  test('a rejected JWT gets one refresh and the same request again', () async {
    final adapter = _QueueAdapter([_text(401, ''), _json(201, _created)]);

    final result = await create(repositoryWith(adapter));

    expect(result.isRight(), isTrue);
    expect(session.refreshCalls, 1);
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.headers['Authorization'], 'Bearer jwt-2');
    expect(adapter.requests.last.headers['Idempotency-Key'], 'key-1');
    expect(adapter.bodies.last, adapter.bodies.first);
  });

  test('a second 401 ends with a session failure', () async {
    final adapter = _QueueAdapter([_text(401, ''), _text(401, '')]);

    final result = await create(repositoryWith(adapter));

    expect(failureCode(result), PixHubErrorCode.sessionUnavailable);
    expect(session.refreshCalls, 1);
  });

  test('no session token means no request', () async {
    session.failure = 'RemoteAuthService not configured';
    final adapter = _QueueAdapter([]);

    final result = await create(repositoryWith(adapter));

    expect(failureCode(result), PixHubErrorCode.sessionUnavailable);
    expect(adapter.requests, isEmpty);
  });

  test('logs an edge rejection with its headers, never the JWT', () async {
    final logs = <String>[];
    final adapter = _QueueAdapter([
      (_) => ResponseBody.fromString(
        '<!DOCTYPE html><html><head><title>Just a moment...</title>',
        403,
        headers: {
          Headers.contentTypeHeader: ['text/html; charset=UTF-8'],
          'server': ['cloudflare'],
          'cf-ray': ['8d1f2a3b4c5d6e7f-GRU'],
          'cf-mitigated': ['challenge'],
        },
      ),
    ]);
    final dio = ApiPixPaymentLinkRepository.createDio(
      baseUrl: 'https://pay.test',
    )..httpClientAdapter = adapter;
    final repository = ApiPixPaymentLinkRepository(
      dio: dio,
      session: session,
      log: logs.add,
    );

    final result = await repository
        .createFixedAmountLink(
          amountInCents: 4590,
          asset: Asset.depix,
          destinationAddress: 'lq1qqf8er278e6nyvuwtgf39e6ewvdcnjupn9a86rzpx6',
          singleUse: true,
          idempotencyKey: 'key-1',
        )
        .run();

    expect(failureCode(result), PixHubErrorCode.serviceUnavailable);
    expect(logs, hasLength(2));
    expect(
      logs.first,
      'request POST https://pay.test/payment-links amount=4590 asset=depix '
      'usage=single_use destination=lq1qqf8e…6rzpx6 idempotency_key=key-1',
    );
    expect(logs.last, startsWith('response http 403 attempt=1 json=false '));
    expect(logs.last, contains('content-type=text/html; charset=UTF-8'));
    expect(logs.last, contains('server=cloudflare'));
    expect(logs.last, contains('cf-ray=8d1f2a3b4c5d6e7f-GRU'));
    expect(logs.last, contains('cf-mitigated=challenge'));
    expect(logs.last, contains('Just a moment...'));
    for (final line in logs) {
      expect(line, isNot(contains('jwt-1')));
    }
  });

  group('maps the API errors', () {
    final cases =
        <String, (ResponseBody Function(RequestOptions), PixHubErrorCode)>{
          '403 INELIGIBLE': (
            _json(403, {'data': null, 'error': 'INELIGIBLE'}),
            PixHubErrorCode.notEligible,
          ),
          '403 Cloudflare challenge page': (
            _text(403, '<!DOCTYPE html><title>Just a moment...</title>'),
            PixHubErrorCode.serviceUnavailable,
          ),
          '400 AMOUNT_OUT_OF_BOUNDS': (
            _json(400, {'data': null, 'error': 'AMOUNT_OUT_OF_BOUNDS'}),
            PixHubErrorCode.amountOutOfBounds,
          ),
          '400 INVALID_INPUT': (
            _json(400, {'data': null, 'error': 'INVALID_INPUT'}),
            PixHubErrorCode.unknown,
          ),
          '404 routes not configured': (
            _text(404, ''),
            PixHubErrorCode.serviceUnavailable,
          ),
          '409 PROVIDER_UNCERTAIN': (
            _json(409, {'data': null, 'error': 'PROVIDER_UNCERTAIN'}),
            PixHubErrorCode.serviceUnavailable,
          ),
          '429 RATE_LIMITED': (
            _json(429, {'data': null, 'error': 'RATE_LIMITED'}),
            PixHubErrorCode.rateLimited,
          ),
          '503 MAINTENANCE': (
            _json(503, {'data': null, 'error': 'MAINTENANCE'}),
            PixHubErrorCode.serviceUnavailable,
          ),
        };

    cases.forEach((name, testCase) {
      test(name, () async {
        final (response, expected) = testCase;
        final adapter = _QueueAdapter([response]);

        final result = await create(repositoryWith(adapter));

        expect(failureCode(result), expected);
        expect(session.refreshCalls, 0);
      });
    });
  });

  group('rejects a success without a usable link', () {
    final bodies = <String, Object>{
      'no data': {'data': null, 'error': null},
      'no url': {
        'data': {'id': 'id-1'},
        'error': null,
      },
      'url without http(s)': {
        'data': {'id': 'id-1', 'url': 'liquidnetwork:lq1qq'},
        'error': null,
      },
      'not JSON': 'created',
    };

    bodies.forEach((name, body) {
      test(name, () async {
        final adapter = _QueueAdapter([
          body is String ? _text(201, body) : _json(201, body),
        ]);

        final result = await create(repositoryWith(adapter));

        expect(failureCode(result), PixHubErrorCode.invalidResponse);
      });
    });
  });

  test('a connection error is a network failure', () async {
    final adapter = _QueueAdapter([
      (options) => throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      ),
    ]);

    final result = await create(repositoryWith(adapter));

    expect(failureCode(result), PixHubErrorCode.network);
  });

  test('reads the paid and expired states and an open amount', () async {
    final data = Map<String, dynamic>.from(_created['data']! as Map);
    final paid = {...data, 'consumed': true};
    final revoked = {...data, 'revoked_at': '2026-10-21T13:30:00Z'};
    final expired = {...data, 'expires_at': '2026-10-21T13:59:00Z'};
    final open = {
      ...data,
      'usage': 'reusable',
      'amount': {'type': 'variable'},
    };
    final adapter = _QueueAdapter([
      for (final item in [paid, revoked, expired, open])
        _json(201, {'data': item, 'error': null}),
    ]);
    final repository = repositoryWith(adapter);

    final links = [
      for (var i = 0; i < 4; i++)
        (await create(repository)).getRight().toNullable()!,
    ];

    expect(links[0].status, PixPaymentLinkStatus.paid);
    expect(links[1].status, PixPaymentLinkStatus.expired);
    expect(links[2].status, PixPaymentLinkStatus.expired);
    expect(links[3].amountInCents, isNull);
    expect(links[3].singleUse, isFalse);
  });

  test('checks the amount bounds and the asset before any request', () async {
    final adapter = _QueueAdapter([]);
    final repository = repositoryWith(adapter);

    final tooLow = await create(repository, amountInCents: 1999);
    final tooHigh = await create(repository, amountInCents: 500001);
    final usdt = await create(repository, asset: Asset.usdt);

    expect(failureCode(tooLow), PixHubErrorCode.amountOutOfBounds);
    expect(failureCode(tooHigh), PixHubErrorCode.amountOutOfBounds);
    expect(failureCode(usdt), PixHubErrorCode.unknown);
    expect(adapter.requests, isEmpty);
    expect(session.getCalls, 0);
  });
}
