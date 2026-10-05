import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/wallet_credentials.dart';
import 'package:mooze_mobile/infra/auth/core_session_authenticator.dart';

import '../core/core_test_fixtures.dart';

class _MockCore extends Mock implements MoozeCore {}

void main() {
  late _MockCore core;
  late CoreSessionAuthenticator auth;
  final creds = WalletCredentials.absent(AppNetwork.mainnet);

  setUp(() {
    core = _MockCore();
    auth = CoreSessionAuthenticator(core: () async => core, logger: MemoryLogger());
  });

  test('ready is Right', () async {
    when(() => core.authEnsureSession())
        .thenAnswer((_) async => const AuthEnsureDto(kind: AuthEnsureKind.ready));

    expect((await auth.ensure(credentials: creds)).isRight(), isTrue);
  });

  test('apiDown and failed are Left', () async {
    when(() => core.authEnsureSession()).thenAnswer((_) async =>
        const AuthEnsureDto(kind: AuthEnsureKind.apiDown, statusCode: 503));
    final r = await auth.ensure(credentials: creds);
    expect(r.getLeft().toNullable()!.message, contains('503'));

    when(() => core.authEnsureSession()).thenAnswer((_) async =>
        const AuthEnsureDto(kind: AuthEnsureKind.failed, message: 'bad sig'));
    final f = await auth.ensure(credentials: creds);
    expect(f.getLeft().toNullable()!.message, contains('bad sig'));
  });

  test('a slow core times out as Left', () async {
    final never = Completer<AuthEnsureDto>();
    when(() => core.authEnsureSession()).thenAnswer((_) => never.future);

    final r = await auth.ensure(
        credentials: creds, timeout: const Duration(milliseconds: 10));

    expect(r.getLeft().toNullable()!.message, contains('timed out'));
  });

  test('a core error is Left', () async {
    when(() => core.authEnsureSession()).thenThrow(
        const CoreError(kind: CoreErrorKind.invalidState, message: 'no store'));

    expect((await auth.ensure(credentials: creds)).isLeft(), isTrue);
  });

  test('invalidate calls the core and swallows errors', () async {
    when(() => core.authInvalidate()).thenThrow(
        const CoreError(kind: CoreErrorKind.storage, message: 'x'));

    await auth.invalidate();

    verify(() => core.authInvalidate()).called(1);
  });
}
