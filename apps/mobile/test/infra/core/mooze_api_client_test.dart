import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/infra/core/mooze_api_client.dart';
import 'package:mooze_mobile/shared/user/services/user_level_storage_service.dart';
import 'package:mooze_mobile/shared/user/services/user_service_impl.dart';

class _MockCore extends Mock implements MoozeCore {}

void main() {
  setUpAll(() => registerFallbackValue(HttpMethodDto.get_));

  late _MockCore core;
  late Dio dio;

  setUp(() {
    core = _MockCore();
    dio = MoozeApiClient(() async => core).dio(baseUrl: 'https://api.test');
  });

  void respond(int status, String body) {
    when(() => core.apiRequest(
          method: any(named: 'method'),
          path: any(named: 'path'),
          jsonBody: any(named: 'jsonBody'),
        )).thenAnswer((_) async => ApiResponseDto(status: status, body: body));
  }

  group('MoozeApiHttpAdapter', () {
    test('sends the relative path and parses a JSON body', () async {
      respond(200, '{"ok":true}');

      final r = await dio.get('/users/me', queryParameters: {'a': '1'});

      expect(r.data, {'ok': true});
      verify(() => core.apiRequest(
            method: HttpMethodDto.get_,
            path: '/users/me?a=1',
            jsonBody: null,
          )).called(1);
    });

    test('passes a Map body to the core as JSON text', () async {
      respond(201, '');

      await dio.post('/users/me/referral', data: {'referral_code': 'ABC'});

      verify(() => core.apiRequest(
            method: HttpMethodDto.post,
            path: '/users/me/referral',
            jsonBody: '{"referral_code":"ABC"}',
          )).called(1);
    });

    test('keeps a base URL path prefix out of the core path', () async {
      dio = MoozeApiClient(() async => core).dio(baseUrl: 'https://api.test/v1/');
      respond(200, '{}');

      await dio.get('/users/me');

      verify(() => core.apiRequest(
            method: HttpMethodDto.get_,
            path: '/users/me',
            jsonBody: null,
          )).called(1);
    });

    test('a non-2xx status becomes a DioException with the response',
        () async {
      respond(409, '{"error":"used"}');

      final e = await dio
          .post('/users/me/referral', data: const {})
          .then<DioException?>((_) => null, onError: (Object e) => e as DioException);

      expect(e!.type, DioExceptionType.badResponse);
      expect(e.response!.statusCode, 409);
      expect(e.response!.data, {'error': 'used'});
    });

    test('a failed session refresh becomes a 401', () async {
      when(() => core.apiRequest(
            method: any(named: 'method'),
            path: any(named: 'path'),
            jsonBody: any(named: 'jsonBody'),
          )).thenThrow(const CoreError(
              kind: CoreErrorKind.session, message: 'refresh failed'));

      final e = await dio
          .get('/users/me')
          .then<DioException?>((_) => null, onError: (Object e) => e as DioException);

      expect(e!.response!.statusCode, 401);
    });

    test('a network error keeps the connection error type', () async {
      when(() => core.apiRequest(
            method: any(named: 'method'),
            path: any(named: 'path'),
            jsonBody: any(named: 'jsonBody'),
          )).thenThrow(
              const CoreError(kind: CoreErrorKind.network, message: 'offline'));

      final e = await dio
          .get('/users/me')
          .then<DioException?>((_) => null, onError: (Object e) => e as DioException);

      expect(e!.type, DioExceptionType.connectionError);
    });

    test('refuses URLs of another host, so no token leaks', () async {
      respond(200, '{}');

      await expectLater(
        dio.get('https://evil.example/users/me'),
        throwsA(isA<DioException>()),
      );
      verifyNever(() => core.apiRequest(
            method: any(named: 'method'),
            path: any(named: 'path'),
            jsonBody: any(named: 'jsonBody'),
          ));
    });
  });

  group('UserServiceImpl over the core', () {
    late UserServiceImpl service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = UserServiceImpl(dio, UserLevelStorageService(prefs));
    });

    test('getUser parses /users/me', () async {
      respond(200, '''
{"data":{"user_id":"u1","verification_level":1,"allowed_spending":1000,
"daily_spending":10,"spending_level":2,"level_progress":0.5,
"to_receive":{"depix":3}}}''');

      final user = (await service.getUser().run()).getOrElse((l) => fail(l));

      expect(user.id, 'u1');
      expect(user.spendingLevel, 2);
      expect(user.valuesToReceive, {'depix': 3});
    });

    test('validateReferralCode maps 404 to false', () async {
      respond(404, '{"error":"not found"}');

      final r = await service.validateReferralCode('X').run();

      expect(r.getOrElse((_) => true), isFalse);
      verify(() => core.apiRequest(
            method: HttpMethodDto.get_,
            path: '/users/referral/X',
            jsonBody: null,
          )).called(1);
    });

    test('addReferral maps 409 to the used-code message', () async {
      respond(409, '{}');

      final r = await service.addReferral('X').run();

      expect(r.getLeft().toNullable(), 'Código de referral já foi usado');
    });
  });
}
