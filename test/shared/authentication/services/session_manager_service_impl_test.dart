import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/shared/authentication/models.dart';
import 'package:mooze_mobile/shared/authentication/services.dart';
import 'package:mooze_mobile/shared/authentication/services/session_manager_service_impl.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockRemoteAuth extends Mock implements RemoteAuthenticationService {}

class _FakeAuthChallenge extends Fake implements AuthChallenge {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Build a JWT whose `exp` claim is [secondsFromNow] from now.
String _jwt({required int secondsFromNow}) {
  final header = base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}'));
  final exp =
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + secondsFromNow;
  final payload =
      base64Url.encode(utf8.encode('{"exp":$exp,"sub":"test"}'));
  return '$header.$payload.sig';
}

String _validJwt() => _jwt(secondsFromNow: 3600);
String _expiredJwt() => _jwt(secondsFromNow: -3600);

/// Dio adapter we control to count refresh calls and respond per-call.
class _RefreshAdapter implements HttpClientAdapter {
  _RefreshAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  int refreshCalls = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    if (options.path == '/auth/refresh') refreshCalls++;
    return handler(options);
  }
}

ResponseBody _jsonBody(int status, Map<String, dynamic> body) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

ResponseBody _httpError(int status) =>
    ResponseBody.fromString('{}', status, headers: {});

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAuthChallenge());
  });

  late _MockSecureStorage storage;
  late _MockRemoteAuth remote;

  setUp(() {
    storage = _MockSecureStorage();
    remote = _MockRemoteAuth();
    when(() => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});
  });

  Dio dioFor(_RefreshAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = adapter;
    return dio;
  }

  group('getSession — single-flight coalescing', () {
    test('N concurrent callers with valid stored JWT → 1 storage read, 0 network',
        () async {
      final jwt = _validJwt();
      when(() => storage.read(key: 'jwt')).thenAnswer((_) async => jwt);
      when(() => storage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'rt-1');

      final adapter = _RefreshAdapter((_) async => _httpError(500));
      final svc = SessionManagerServiceImpl(
        secureStorage: storage,
        dio: dioFor(adapter),
        remoteAuthService: remote,
      );

      final results = await Future.wait(
        List.generate(10, (_) => svc.getSession().run()),
      );

      for (final r in results) {
        expect(r.isRight(), isTrue);
      }
      expect(adapter.refreshCalls, 0);
      // Cache means at most one pair of storage reads.
      verify(() => storage.read(key: 'jwt')).called(1);
      verify(() => storage.read(key: 'refresh_token')).called(1);
    });

    test('N concurrent callers with expired JWT → exactly 1 /auth/refresh',
        () async {
      final expired = _expiredJwt();
      final fresh = _validJwt();
      when(() => storage.read(key: 'jwt')).thenAnswer((_) async => expired);
      when(() => storage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'rt-1');

      final adapter = _RefreshAdapter((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _jsonBody(200, {'jwt': fresh});
      });
      final svc = SessionManagerServiceImpl(
        secureStorage: storage,
        dio: dioFor(adapter),
        remoteAuthService: remote,
      );

      final results = await Future.wait(
        List.generate(10, (_) => svc.getSession().run()),
      );

      for (final r in results) {
        expect(r.isRight(), isTrue);
        expect(r.getRight().toNullable()!.jwt, fresh);
      }
      expect(adapter.refreshCalls, 1,
          reason: 'all 10 callers must coalesce into one refresh');
    });
  });

  group('refresh-race recovery', () {
    test(
        'when refresh returns 404 but storage has fresh JWT → return stored, no challenge',
        () async {
      final expired = _expiredJwt();
      final fresh = _validJwt();

      // First read returns expired; subsequent reads return fresh (the
      // "winner" of a parallel refresh has just persisted it).
      var reads = 0;
      when(() => storage.read(key: 'jwt')).thenAnswer((_) async {
        reads++;
        return reads == 1 ? expired : fresh;
      });
      when(() => storage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'rt-old');

      final adapter = _RefreshAdapter((opts) async {
        if (opts.path == '/auth/refresh') {
          return _httpError(404);
        }
        fail('no other endpoint should be hit: ${opts.path}');
      });
      final svc = SessionManagerServiceImpl(
        secureStorage: storage,
        dio: dioFor(adapter),
        remoteAuthService: remote,
      );

      // Force a fresh instance whose cache is empty so the second read hits
      // storage again. (The implementation re-reads after refresh failure.)
      final r = await svc.getSession().run();

      expect(r.isRight(), isTrue);
      expect(r.getRight().toNullable()!.jwt, fresh,
          reason: 'must reuse the JWT another caller persisted');
      verifyNever(() => remote.requestLoginChallenge());
    });

    test(
        'when refresh returns 404 and storage stays empty → falls through to challenge/sign',
        () async {
      final expired = _expiredJwt();
      final brandNew = _validJwt();

      when(() => storage.read(key: 'jwt')).thenAnswer((_) async => expired);
      when(() => storage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'rt-old');

      final adapter = _RefreshAdapter((opts) async {
        if (opts.path == '/auth/refresh') return _httpError(404);
        return _httpError(500);
      });

      when(() => remote.requestLoginChallenge())
          .thenReturn(TaskEither.right(_FakeAuthChallenge()));
      when(() => remote.signChallenge(any())).thenReturn(
        TaskEither.right(Session(jwt: brandNew, refreshToken: 'rt-new')),
      );

      final svc = SessionManagerServiceImpl(
        secureStorage: storage,
        dio: dioFor(adapter),
        remoteAuthService: remote,
      );

      final r = await svc.getSession().run();

      expect(r.isRight(), isTrue);
      expect(r.getRight().toNullable()!.jwt, brandNew);
      verify(() => remote.requestLoginChallenge()).called(1);
      verify(() => remote.signChallenge(any())).called(1);
    });
  });

  group('create-session single-flight', () {
    test(
        'N concurrent callers with empty storage → exactly 1 challenge + 1 sign',
        () async {
      final brandNew = _validJwt();
      when(() => storage.read(key: 'jwt')).thenAnswer((_) async => null);
      when(() => storage.read(key: 'refresh_token'))
          .thenAnswer((_) async => null);

      var challengeCalls = 0;
      var signCalls = 0;
      when(() => remote.requestLoginChallenge()).thenAnswer((_) {
        return TaskEither(() async {
          challengeCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return Right<String, AuthChallenge>(_FakeAuthChallenge());
        });
      });
      when(() => remote.signChallenge(any())).thenAnswer((_) {
        return TaskEither(() async {
          signCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return Right<String, Session>(
              Session(jwt: brandNew, refreshToken: 'rt-new'));
        });
      });

      final svc = SessionManagerServiceImpl(
        secureStorage: storage,
        dio: dioFor(_RefreshAdapter((_) async => _httpError(500))),
        remoteAuthService: remote,
      );

      final results = await Future.wait(
        List.generate(10, (_) => svc.getSession().run()),
      );

      for (final r in results) {
        expect(r.isRight(), isTrue);
        expect(r.getRight().toNullable()!.jwt, brandNew);
      }
      expect(challengeCalls, 1);
      expect(signCalls, 1);
    });
  });

  group('forceRefresh', () {
    test('N concurrent forceRefresh calls → exactly 1 /auth/refresh',
        () async {
      final valid = _validJwt(); // not expired — interceptor scenario
      final fresh = _validJwt();
      when(() => storage.read(key: 'jwt')).thenAnswer((_) async => valid);
      when(() => storage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'rt-1');

      final adapter = _RefreshAdapter((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return _jsonBody(200, {'jwt': fresh});
      });
      final svc = SessionManagerServiceImpl(
        secureStorage: storage,
        dio: dioFor(adapter),
        remoteAuthService: remote,
      );

      final results = await Future.wait(
        List.generate(8, (_) => svc.forceRefresh().run()),
      );

      for (final r in results) {
        expect(r.isRight(), isTrue);
      }
      expect(adapter.refreshCalls, 1);
    });
  });

  group('rotating refresh tokens', () {
    test('refresh response with new refresh_token is persisted', () async {
      final expired = _expiredJwt();
      final fresh = _validJwt();
      when(() => storage.read(key: 'jwt')).thenAnswer((_) async => expired);
      when(() => storage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'rt-old');

      final adapter = _RefreshAdapter(
        (_) async => _jsonBody(200, {
          'jwt': fresh,
          'refresh_token': 'rt-NEW',
        }),
      );
      final svc = SessionManagerServiceImpl(
        secureStorage: storage,
        dio: dioFor(adapter),
        remoteAuthService: remote,
      );

      final r = await svc.getSession().run();

      expect(r.isRight(), isTrue);
      expect(r.getRight().toNullable()!.refreshToken, 'rt-NEW');
      verify(() => storage.write(key: 'refresh_token', value: 'rt-NEW'))
          .called(1);
    });
  });

  group('refresh response envelope shapes', () {
    test('flat response {jwt: ...} is accepted', () async {
      final expired = _expiredJwt();
      final fresh = _validJwt();
      when(() => storage.read(key: 'jwt')).thenAnswer((_) async => expired);
      when(() => storage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'rt');

      final adapter =
          _RefreshAdapter((_) async => _jsonBody(200, {'jwt': fresh}));
      final svc = SessionManagerServiceImpl(
        secureStorage: storage,
        dio: dioFor(adapter),
        remoteAuthService: remote,
      );

      final r = await svc.getSession().run();
      expect(r.isRight(), isTrue);
      expect(r.getRight().toNullable()!.jwt, fresh);
      verifyNever(() => remote.requestLoginChallenge());
    });

    test('wrapped response {data: {jwt: ...}} is accepted', () async {
      final expired = _expiredJwt();
      final fresh = _validJwt();
      when(() => storage.read(key: 'jwt')).thenAnswer((_) async => expired);
      when(() => storage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'rt');

      final adapter = _RefreshAdapter(
        (_) async => _jsonBody(200, {
          'data': {'jwt': fresh, 'refresh_token': 'rt-rotated'},
        }),
      );
      final svc = SessionManagerServiceImpl(
        secureStorage: storage,
        dio: dioFor(adapter),
        remoteAuthService: remote,
      );

      final r = await svc.getSession().run();
      expect(r.isRight(), isTrue);
      expect(r.getRight().toNullable()!.jwt, fresh);
      expect(r.getRight().toNullable()!.refreshToken, 'rt-rotated');
      verifyNever(() => remote.requestLoginChallenge());
    });

    test('200 with no jwt anywhere → falls through to challenge/sign',
        () async {
      final expired = _expiredJwt();
      final fresh = _validJwt();
      when(() => storage.read(key: 'jwt')).thenAnswer((_) async => expired);
      when(() => storage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'rt');

      final adapter = _RefreshAdapter(
        (opts) async {
          if (opts.path == '/auth/refresh') return _jsonBody(200, {});
          return _httpError(500);
        },
      );
      when(() => remote.requestLoginChallenge())
          .thenReturn(TaskEither.right(_FakeAuthChallenge()));
      when(() => remote.signChallenge(any())).thenReturn(
        TaskEither.right(Session(jwt: fresh, refreshToken: 'rt-new')),
      );

      final svc = SessionManagerServiceImpl(
        secureStorage: storage,
        dio: dioFor(adapter),
        remoteAuthService: remote,
      );

      final r = await svc.getSession().run();
      expect(r.isRight(), isTrue);
      expect(r.getRight().toNullable()!.jwt, fresh);
      verify(() => remote.requestLoginChallenge()).called(1);
      verify(() => remote.signChallenge(any())).called(1);
    });
  });

  group('saveSession / deleteSession', () {
    test('saveSession persists both keys atomically', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final svc = SessionManagerServiceImpl(
        secureStorage: storage,
        dio: dioFor(_RefreshAdapter((_) async => _httpError(500))),
      );

      final r =
          await svc.saveSession(Session(jwt: 'j', refreshToken: 'r')).run();
      expect(r.isRight(), isTrue);
      verify(() => storage.write(key: 'jwt', value: 'j')).called(1);
      verify(() => storage.write(key: 'refresh_token', value: 'r')).called(1);
    });

    test('deleteSession removes both keys atomically', () async {
      final svc = SessionManagerServiceImpl(
        secureStorage: storage,
        dio: dioFor(_RefreshAdapter((_) async => _httpError(500))),
      );

      final r = await svc.deleteSession().run();
      expect(r.isRight(), isTrue);
      verify(() => storage.delete(key: 'jwt')).called(1);
      verify(() => storage.delete(key: 'refresh_token')).called(1);
    });
  });
}
