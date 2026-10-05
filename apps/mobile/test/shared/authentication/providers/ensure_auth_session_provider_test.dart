import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart' show moozeCoreProvider;
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_down_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/sync_error_indicator.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';

class _MockCore extends Mock implements MoozeCore {}

void main() {
  late _MockCore core;

  setUp(() => core = _MockCore());

  ProviderContainer container({Option<String> mnemonic = const Some('m')}) {
    final c = ProviderContainer(overrides: [
      mnemonicProvider.overrideWith((ref) async => mnemonic),
      moozeCoreProvider.overrideWith((ref) async => core),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  void ensureReturns(AuthEnsureDto dto) =>
      when(() => core.authEnsureSession()).thenAnswer((_) async => dto);

  test('ready clears every flag', () async {
    ensureReturns(const AuthEnsureDto(kind: AuthEnsureKind.ready));
    final c = container();
    c.read(syncErrorProvider.notifier).state = true;
    c.read(apiDownProvider.notifier).state = true;
    c.read(apiStatusCodeProvider.notifier).state = 503;

    expect(await c.read(ensureAuthSessionProvider.future), isTrue);
    expect(c.read(syncErrorProvider), isFalse);
    expect(c.read(syncErrorMessageProvider), isNull);
    expect(c.read(apiDownProvider), isFalse);
    expect(c.read(apiStatusCodeProvider), isNull);
  });

  test('no mnemonic sets the sync error without calling the core', () async {
    final c = container(mnemonic: const None());

    expect(await c.read(ensureAuthSessionProvider.future), isFalse);
    expect(c.read(syncErrorProvider), isTrue);
    expect(c.read(syncErrorMessageProvider), 'Mnemônico não encontrado');
    verifyNever(() => core.authEnsureSession());
  });

  test('apiDown sets the API-down flag and status code', () async {
    ensureReturns(
        const AuthEnsureDto(kind: AuthEnsureKind.apiDown, statusCode: 502));
    final c = container();

    expect(await c.read(ensureAuthSessionProvider.future), isFalse);
    expect(c.read(apiDownProvider), isTrue);
    expect(c.read(apiStatusCodeProvider), 502);
    expect(c.read(syncErrorProvider), isFalse);
  });

  test('failed sets the sync error message', () async {
    ensureReturns(
        const AuthEnsureDto(kind: AuthEnsureKind.failed, message: 'bad sig'));
    final c = container();

    expect(await c.read(ensureAuthSessionProvider.future), isFalse);
    expect(c.read(syncErrorProvider), isTrue);
    expect(c.read(syncErrorMessageProvider), 'bad sig');
    expect(c.read(apiDownProvider), isFalse);
  });

  test('a core error counts as failed', () async {
    when(() => core.authEnsureSession()).thenThrow(const CoreError(
        kind: CoreErrorKind.invalidState, message: 'secure storage not set'));
    final c = container();

    expect(await c.read(ensureAuthSessionProvider.future), isFalse);
    expect(c.read(syncErrorProvider), isTrue);
    expect(c.read(syncErrorMessageProvider), contains('secure storage'));
  });

  test('refreshAuthSessionProvider returns the core result', () async {
    when(() => core.authRefreshCurrent()).thenAnswer((_) async => true);
    final c = container();
    final sub = c.listen(refreshAuthSessionProvider.future, (_, _) {});
    addTearDown(sub.close);

    expect(await sub.read(), isTrue);
  });
}
