import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/data/repositories/api_pix_withdrawal_repository.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
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
  int refreshCalls = 0;
  String? failure;

  @override
  TaskEither<String, Session> getSession() => failure == null
      ? TaskEither.right(Session(jwt: 'jwt-1', refreshToken: 'rt'))
      : TaskEither.left(failure!);

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

ResponseBody Function(RequestOptions) _json(
  int status,
  Object body, {
  String? date,
}) =>
    (_) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        if (date != null) 'date': [date],
      },
    );

ResponseBody Function(RequestOptions) _text(int status, String body) =>
    (_) => ResponseBody.fromString(body, status);

/// `WithdrawCreated` of the OpenAPI document, for a R$ 45,90 payout.
Map<String, Object?> _created({
  Object? asset = depixAssetId,
  Object? depositCents = 4689,
  Object? depositSats = 4689000000,
  Object? payoutCents = 4590,
  Object? address =
      'lq1qqf8er278e6nyvuwtgf39e6ewvdcnjupn9a86rzpx655y5lm8w6k9ruw2n',
}) => {
  'data': {
    'id': '0b6f2f8e-8f0e-4b8a-9a52-2f1d9c7e4b10',
    'provider_id': 'eulen-77',
    'deposit_address': address,
    'asset': asset,
    'deposit_amount_in_cents': depositCents,
    'deposit_amount_sats': depositSats,
    'payout_amount_in_cents': payoutCents,
    'expires_at': '2026-10-24T12:30:00Z',
  },
  'error': null,
};

void main() {
  late _FakeSession session;
  final now = DateTime.utc(2026, 10, 24, 12);

  ApiPixWithdrawalRepository repositoryWith(_QueueAdapter adapter) {
    final dio = ApiPixWithdrawalRepository.createDio(
      baseUrl: 'https://api.test',
    )..httpClientAdapter = adapter;
    return ApiPixWithdrawalRepository(
      dio: dio,
      session: session,
      now: () => now,
    );
  }

  Future<Either<PixHubFailure, PixWithdrawal>> create(
    ApiPixWithdrawalRepository repository, {
    int payout = 4590,
  }) {
    return repository
        .create(
          pixKey: ' ana@exemplo.com.br ',
          payoutAmountInCents: payout,
          taxId: '52998224725',
          refundAddress: 'lq1qqrefund',
        )
        .run();
  }

  PixHubErrorCode failureCode(Either<PixHubFailure, Object> result) =>
      result.getLeft().toNullable()!.code;

  setUp(() => session = _FakeSession());

  group('create', () {
    test('sends the request of the OpenAPI contract', () async {
      final adapter = _QueueAdapter([_json(200, _created())]);

      final result = await create(repositoryWith(adapter));

      final withdrawal = result.getRight().toNullable()!;
      expect(withdrawal.id, '0b6f2f8e-8f0e-4b8a-9a52-2f1d9c7e4b10');
      expect(withdrawal.providerId, 'eulen-77');
      expect(withdrawal.assetId, depixAssetId);
      expect(withdrawal.depositAmountInCents, 4689);
      expect(withdrawal.depositAmountSats, 4689000000);
      expect(withdrawal.payoutAmountInCents, 4590);
      expect(withdrawal.feeInCents, 99);
      expect(withdrawal.expiresAt, DateTime.utc(2026, 10, 24, 12, 30));

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.toString(), 'https://api.test/withdraw');
      expect(request.headers['Authorization'], 'Bearer jwt-1');
      expect(request.contentType, startsWith('application/json'));
      // The API rejects unknown fields, so the body has exactly these keys.
      expect(jsonDecode(adapter.bodies.single), {
        'pix_key': 'ana@exemplo.com.br',
        'payout_amount_in_cents': 4590,
        'tax_id': '52998224725',
        'refund_address': 'lq1qqrefund',
      });
    });

    test('measures the deadline on the server clock', () async {
      // The server clock is 10 minutes behind the device clock.
      final adapter = _QueueAdapter([
        _json(200, _created(), date: 'Sat, 24 Oct 2026 11:50:00 GMT'),
      ]);

      final result = await create(repositoryWith(adapter));

      // 40 minutes remain on the server clock, so the device deadline is
      // 12:40, not 12:30.
      expect(
        result.getRight().toNullable()!.fundingDeadline,
        DateTime.utc(2026, 10, 24, 12, 40),
      );
    });

    test('an amount outside the bounds sends no request', () async {
      final adapter = _QueueAdapter([]);

      final low = await create(repositoryWith(adapter), payout: 199);
      final high = await create(repositoryWith(adapter), payout: 600001);

      expect(failureCode(low), PixHubErrorCode.amountOutOfBounds);
      expect(failureCode(high), PixHubErrorCode.amountOutOfBounds);
      expect(adapter.requests, isEmpty);
    });

    test('a rejected JWT gets one refresh and the same request', () async {
      final adapter = _QueueAdapter([_text(401, ''), _json(200, _created())]);

      final result = await create(repositoryWith(adapter));

      expect(result.isRight(), isTrue);
      expect(session.refreshCalls, 1);
      expect(adapter.requests.last.headers['Authorization'], 'Bearer jwt-2');
      expect(adapter.bodies.last, adapter.bodies.first);
    });

    test('a second 401 ends with a session failure', () async {
      final adapter = _QueueAdapter([_text(401, ''), _text(401, '')]);

      final result = await create(repositoryWith(adapter));

      expect(failureCode(result), PixHubErrorCode.sessionUnavailable);
      expect(adapter.requests, hasLength(2));
    });

    test('no session token means no request', () async {
      session.failure = 'not configured';
      final adapter = _QueueAdapter([]);

      final result = await create(repositoryWith(adapter));

      expect(failureCode(result), PixHubErrorCode.sessionUnavailable);
      expect(adapter.requests, isEmpty);
    });

    group('maps the API errors', () {
      Map<String, Object?> envelope(String error) => {
        'data': null,
        'error': error,
      };
      final cases =
          <String, (ResponseBody Function(RequestOptions), PixHubErrorCode)>{
            '400 invalid input': (
              _json(400, envelope('invalid pix key')),
              PixHubErrorCode.invalidRequest,
            ),
            '403 allowance': (
              _json(403, envelope('allowance exceeded')),
              PixHubErrorCode.limitExceeded,
            ),
            '403 from the edge': (
              _text(403, '<html>Just a moment...</html>'),
              PixHubErrorCode.serviceUnavailable,
            ),
            '404 route missing': (
              _text(404, ''),
              PixHubErrorCode.serviceUnavailable,
            ),
            '422 provider refusal': (
              _json(422, envelope('pix key does not belong to tax id')),
              PixHubErrorCode.providerRefused,
            ),
            '429 open withdrawals': (
              _json(429, envelope('too many open withdrawals')),
              PixHubErrorCode.rateLimited,
            ),
            '500 internal': (
              _json(500, envelope('storage')),
              PixHubErrorCode.serviceUnavailable,
            ),
            '503 unknown outcome': (
              _json(503, envelope('provider uncertain')),
              PixHubErrorCode.outcomeUnknown,
            ),
          };
      cases.forEach((name, value) {
        test(name, () async {
          final adapter = _QueueAdapter([value.$1]);
          final result = await create(repositoryWith(adapter));
          expect(failureCode(result), value.$2);
        });
      });
    });

    test('logs the HTTP status of a failure, without personal data', () async {
      final logs = <String>[];
      final dio =
          ApiPixWithdrawalRepository.createDio(baseUrl: 'https://api.test')
            ..httpClientAdapter = _QueueAdapter([
              _json(500, {
                'data': null,
                'error': 'eulen rejected ana@exemplo.com.br 52998224725',
              }),
            ]);
      final repository = ApiPixWithdrawalRepository(
        dio: dio,
        session: session,
        log: logs.add,
      );

      final result = await create(repository);

      expect(failureCode(result), PixHubErrorCode.serviceUnavailable);
      expect(logs.single, startsWith('create: http 500, json'));
      expect(logs.single, contains('eulen rejected ***@*** ****'));
      for (final secret in [
        'ana@exemplo.com.br',
        '52998224725',
        'lq1qqrefund',
        'jwt-1',
      ]) {
        expect(logs.single, isNot(contains(secret)));
      }
    });

    test('a timeout is a network failure', () async {
      final adapter = _QueueAdapter([
        (options) => throw DioException.receiveTimeout(
          timeout: const Duration(seconds: 30),
          requestOptions: options,
        ),
      ]);

      final result = await create(repositoryWith(adapter));

      expect(failureCode(result), PixHubErrorCode.network);
    });

    group('refuses an answer that does not match the request', () {
      final cases = <String, (Map<String, Object?>, PixHubErrorCode)>{
        'another asset': (
          _created(asset: lbtcAssetId),
          PixHubErrorCode.quoteMismatch,
        ),
        'another payout': (
          _created(payoutCents: 4500),
          PixHubErrorCode.quoteMismatch,
        ),
        'a deposit below the payout': (
          _created(depositCents: 4000, depositSats: 4000000000),
          PixHubErrorCode.quoteMismatch,
        ),
        'sats that do not match the cents': (
          _created(depositSats: 4689000001),
          PixHubErrorCode.quoteMismatch,
        ),
        'a fractional amount': (
          _created(depositCents: 4689.5),
          PixHubErrorCode.invalidResponse,
        ),
        'a URI as the address': (
          _created(address: 'liquidnetwork:lq1qqabc?amount=1'),
          PixHubErrorCode.invalidResponse,
        ),
        'no data': (
          {'data': null, 'error': null},
          PixHubErrorCode.invalidResponse,
        ),
      };
      cases.forEach((name, value) {
        test(name, () async {
          final adapter = _QueueAdapter([_json(200, value.$1)]);
          final result = await create(repositoryWith(adapter));
          expect(failureCode(result), value.$2);
        });
      });
    });
  });

  group('statuses', () {
    test('repeats the ids key and reads WithdrawDetails', () async {
      final adapter = _QueueAdapter([
        _json(200, {
          'data': [
            {
              'id': 'w-1',
              'status': 'sent',
              'pix_key': 'ana@exemplo.com.br',
              'deposit_address': 'lq1qqdeposit',
              'deposit_amount_in_cents': 4689,
              'payout_amount_in_cents': 4590,
              'expires_at': '2026-10-24T12:30:00Z',
              'blockchain_txid': 'ab12',
              'receipt_url': 'https://eulen.app/receipt/1',
              'receiver_name': 'Ana Souza',
              'receiver_tax_number': '***.982.247-**',
              'transfer_date': '2026-10-24T12:05:00Z',
              'central_bank_id': 'E1234567820261024120500000000001',
              'refund': null,
              'created_at': '2026-10-24T12:00:00Z',
            },
            {
              'id': 'w-2',
              'status': 'refunded',
              'pix_key': 'ana@exemplo.com.br',
              'deposit_address': null,
              'deposit_amount_in_cents': null,
              'payout_amount_in_cents': null,
              'expires_at': null,
              'blockchain_txid': null,
              'receipt_url': null,
              'receiver_name': null,
              'receiver_tax_number': null,
              'transfer_date': null,
              'central_bank_id': null,
              'refund': {
                'reason': 'late deposit',
                'txId': 'cd34',
                'initiatedBy': 'provider',
                'feeInCents': 10,
                'netAmountInCents': 4679,
              },
              'created_at': '2026-10-24T11:00:00Z',
            },
            {'id': 'w-3', 'status': 'sent'},
          ],
          'error': null,
        }),
      ]);

      final result = await repositoryWith(
        adapter,
      ).statuses(['w-1', 'w-2', 'w-3']).run();

      expect(
        adapter.requests.single.uri.toString(),
        'https://api.test/withdraw/status?ids=w-1&ids=w-2&ids=w-3',
      );
      final list = result.getRight().toNullable()!;
      // The item without created_at is left out.
      expect(list, hasLength(2));
      expect(list[0].status, PixWithdrawalStatus.sent);
      expect(list[0].receiptUrl, 'https://eulen.app/receipt/1');
      expect(list[0].centralBankId, 'E1234567820261024120500000000001');
      expect(list[0].transferDate, DateTime.utc(2026, 10, 24, 12, 5));
      expect(list[1].status, PixWithdrawalStatus.refunded);
      expect(list[1].refund?.netAmountInCents, 4679);
      expect(list[1].refund?.txId, 'cd34');
    });

    test('an empty list sends no request', () async {
      final adapter = _QueueAdapter([]);

      final result = await repositoryWith(adapter).statuses([]).run();

      expect(result.getRight().toNullable(), isEmpty);
      expect(adapter.requests, isEmpty);
    });

    test('a 503 is a service failure, not an unknown outcome', () async {
      final adapter = _QueueAdapter([_text(503, '')]);

      final result = await repositoryWith(adapter).statuses(['w-1']).run();

      expect(failureCode(result), PixHubErrorCode.serviceUnavailable);
    });
  });

  group('PixWithdrawalStatus', () {
    test('marks the final statuses of the contract', () {
      final finals = PixWithdrawalStatus.values.where((s) => s.isFinal);
      expect(finals, {
        PixWithdrawalStatus.sent,
        PixWithdrawalStatus.canceled,
        PixWithdrawalStatus.refunded,
        PixWithdrawalStatus.replaced,
        PixWithdrawalStatus.rejected,
      });
    });

    test('only sent is a completed payment', () {
      final completed = PixWithdrawalStatus.values.where((s) => s.isCompleted);
      expect(completed, [PixWithdrawalStatus.sent]);
    });

    test('an unknown value is open, never final', () {
      final status = PixWithdrawalStatus.parse('settled');
      expect(status, PixWithdrawalStatus.unknown);
      expect(status.isFinal, isFalse);
    });
  });
}
