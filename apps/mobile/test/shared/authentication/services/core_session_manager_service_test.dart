import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/shared/authentication/models.dart';
import 'package:mooze_mobile/shared/authentication/services/core_session_manager_service.dart';

class _MockCore extends Mock implements MoozeCore {}

void main() {
  late _MockCore core;
  late CoreSessionManagerService service;

  setUp(() {
    core = _MockCore();
    service = CoreSessionManagerService(() async => core);
    when(() => core.secureGet(key: 'refresh_token'))
        .thenAnswer((_) async => 'refresh-1');
  });

  test('getSession returns the core token and the stored refresh token',
      () async {
    when(() => core.authAccessToken()).thenAnswer((_) async => 'jwt-1');

    final s = (await service.getSession().run()).getOrElse((l) => fail(l));

    expect(s.jwt, 'jwt-1');
    expect(s.refreshToken, 'refresh-1');
  });

  test('getSession maps a core error to Left with its message', () async {
    when(() => core.authAccessToken()).thenThrow(
        const CoreError(kind: CoreErrorKind.session, message: 'no mnemonic'));

    final r = await service.getSession().run();

    expect(r.getLeft().toNullable(), contains('no mnemonic'));
  });

  test('forceRefresh and refreshSession use the core refresh', () async {
    when(() => core.authForceRefresh()).thenAnswer((_) async => 'jwt-2');

    final a = await service.forceRefresh().run();
    final b = await service
        .refreshSession(Session(jwt: 'old', refreshToken: 'r'))
        .run();

    expect(a.map((s) => s.jwt).toNullable(), 'jwt-2');
    expect(b.map((s) => s.jwt).toNullable(), 'jwt-2');
    verify(() => core.authForceRefresh()).called(2);
  });

  test('deleteSession invalidates the core session', () async {
    when(() => core.authInvalidate()).thenAnswer((_) async {});

    expect((await service.deleteSession().run()).isRight(), isTrue);
    verify(() => core.authInvalidate()).called(1);
  });

  test('saveSession stores both keys, then resets the core cache', () async {
    final order = <String>[];
    when(() => core.securePut(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((i) async => order.add('put ${i.namedArguments[#key]}'));
    when(() => core.authReset()).thenAnswer((_) async => order.add('reset'));

    await service.saveSession(Session(jwt: 'j', refreshToken: 'r')).run();

    expect(order, ['put jwt', 'put refresh_token', 'reset']);
  });

  test('resetIdentity calls authReset', () async {
    when(() => core.authReset()).thenAnswer((_) async {});

    expect((await service.resetIdentity().run()).isRight(), isTrue);
    verify(() => core.authReset()).called(1);
  });

  test('a failed core open becomes Left', () async {
    service =
        CoreSessionManagerService(() async => throw StateError('closed'));

    expect((await service.getSession().run()).isLeft(), isTrue);
    expect((await service.resetIdentity().run()).isLeft(), isTrue);
  });
}
