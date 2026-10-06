import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

/// Calls the real native library from Dart, on the host.
///
/// Build it first with `cargo build` in `rust/`. Set `MOOZE_CORE_BRIDGE_LIB`
/// to use a library built elsewhere, for example with `CARGO_TARGET_DIR`.
/// The test skips when the library is missing, so `flutter test` still runs
/// on machines without Rust.
const _abandon =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

/// Unsigned JWT that expires in 2100.
const _farFutureJwt =
    'eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJleHAiOjQxMDI0NDQ4MDAsInN1YiI6InUxIn0.sig';

String? _hostLibrary() {
  final name = Platform.isMacOS
      ? 'libmooze_core_bridge.dylib'
      : Platform.isWindows
      ? 'mooze_core_bridge.dll'
      : 'libmooze_core_bridge.so';
  final path =
      Platform.environment['MOOZE_CORE_BRIDGE_LIB'] ??
      'rust/target/debug/$name';
  return File(path).existsSync() ? path : null;
}

void main() {
  final library = _hostLibrary();

  setUpAll(() async {
    if (library != null) {
      await MoozeCoreLib.init(externalLibrary: ExternalLibrary.open(library));
    }
  });

  Future<MoozeCore> openCore() async {
    final dir = await Directory.systemTemp.createTemp('mooze-core-bridge-');
    addTearDown(() => dir.delete(recursive: true));
    return MoozeCore.open(
      config: CoreConfig(
        dataDir: dir.path,
        network: NetworkDto.mainnet,
        backend: BackendDto.electrum,
        bitcoinNodeUrl: '',
        liquidNodeUrl: '',
      ),
    );
  }

  test(
    'derives the same first addresses as the Flutter app',
    () async {
      final core = await openCore();
      await core.bitcoinConnect(mnemonic: _abandon);
      final btc = await core.bitcoinReceiveAddress();
      expect(btc.address, 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu');

      await core.liquidConnect(mnemonic: _abandon);
      final lq = await core.liquidReceiveAddress();
      expect(lq.address, startsWith('lq1'));
      expect(await core.liquidTransactions(), isEmpty);
    },
    skip: library == null ? 'native library not built' : false,
  );

  test(
    'explorer calls derive, probe and list without revealing',
    () async {
      final core = await openCore();
      await core.bitcoinConnect(mnemonic: _abandon);
      final ext = await core.bitcoinDerivedAddresses(
        keychain: KeychainDto.external_,
        start: 0,
        count: 2,
      );
      expect(ext.map((a) => a.index), [0, 1]);
      expect(ext.first.address, 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu');
      expect(ext[1].address, 'bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g');
      expect(
        ext.every((a) => !a.used && a.keychain == KeychainDto.external_),
        isTrue,
      );
      final change = await core.bitcoinDerivedAddresses(
        keychain: KeychainDto.internal,
        start: 0,
        count: 1,
      );
      expect(
        change.single.address,
        'bc1q8c6fshw2dlwun7ekn9qwf37cu2rn755upcp6el',
      );

      final own = await core.bitcoinIsMine(address: ext[1].address);
      expect(own?.keychain, KeychainDto.external_);
      expect(own?.index, 1);
      final ownChange = await core.bitcoinIsMine(
        address: change.single.address,
      );
      expect(ownChange?.keychain, KeychainDto.internal);
      expect(
        await core.bitcoinIsMine(
          address: 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
        ),
        isNull,
      );
      await expectLater(
        core.bitcoinIsMine(address: 'garbage'),
        throwsA(
          isA<CoreError>().having(
            (e) => e.kind,
            'kind',
            CoreErrorKind.invalidInput,
          ),
        ),
      );
      expect(await core.bitcoinUnspentOutputs(), isEmpty);
      final next = await core.bitcoinNextUnusedAddress();
      expect(next.index, 0);
      expect(next.address, ext.first.address);
      expect(next.used, isFalse);

      await core.liquidConnect(mnemonic: _abandon);
      final lq = await core.liquidDerivedAddresses(
        keychain: KeychainDto.external_,
        start: 0,
        count: 3,
      );
      expect(lq.map((a) => a.index), [0, 1, 2]);
      expect(lq.every((a) => a.address.startsWith('lq1')), isTrue);
      expect(lq.every((a) => a.unconfidential!.startsWith('ex1')), isTrue);
      final lqOwn = await core.liquidIsMine(
        address: lq[2].unconfidential!,
        scanLimit: 200,
      );
      expect(lqOwn?.index, 2);
      expect(
        await core.liquidIsMine(address: lq[2].address, scanLimit: 2),
        isNull,
      );
      expect(await core.liquidUnspentOutputs(), isEmpty);
      final lqNext = await core.liquidNextUnusedAddress();
      expect(lqNext.index, 0);
      expect(lqNext.address, lq.first.address);
      expect(lqNext.used, isFalse);
    },
    skip: library == null ? 'native library not built' : false,
  );

  test(
    'imports the golden snapshot once',
    () async {
      final core = await openCore();
      expect(await core.isMigrated(), isFalse);
      final json = File(
        '../../crates/mooze-core/tests/fixtures/flutter_snapshot_v1.json',
      ).readAsStringSync();
      final report = await core.importFlutterSnapshot(snapshotJson: json);
      expect(report.alreadyDone, isFalse);
      expect(report.skipped, isEmpty);
      expect(
        report.copied.firstWhere((c) => c.table == 'transactions').count,
        1,
      );
      expect(await core.isMigrated(), isTrue);
      final again = await core.importFlutterSnapshot(snapshotJson: json);
      expect(again.alreadyDone, isTrue);
    },
    skip: library == null ? 'native library not built' : false,
  );

  test(
    'calls before connect throw CoreError',
    () async {
      final core = await openCore();
      await expectLater(
        core.bitcoinBalance(),
        throwsA(
          isA<CoreError>().having(
            (e) => e.kind,
            'kind',
            CoreErrorKind.invalidState,
          ),
        ),
      );
    },
    skip: library == null ? 'native library not built' : false,
  );

  test(
    'reads and writes secrets through the Dart secure-storage callbacks',
    () async {
      final core = await openCore();
      // Same shape as a flutter_secure_storage adapter: listKeys filters
      // the keys of readAll().
      final storage = <String, String>{'from_dart': 'çü value'};
      await core.setSecureStorage(
        read: (key) async => storage[key],
        write: (key, value) async => storage[key] = value,
        delete: (key) async => storage.remove(key),
        listKeys: (prefix) async =>
            storage.keys.where((k) => k.startsWith(prefix)).toList(),
      );

      expect(await core.secureGet(key: 'from_dart'), 'çü value');
      expect(await core.secureGet(key: 'absent'), isNull);
      await core.securePut(key: 'from_core', value: 'token');
      expect(storage['from_core'], 'token');
      expect(await core.secureListKeys(prefix: 'from_'), [
        'from_core',
        'from_dart',
      ]);
      await core.secureDelete(key: 'from_core');
      expect(storage.containsKey('from_core'), isFalse);

      final id = await core.authDeviceId(serial: null, platformId: 'android-1');
      expect(storage['device_id'], id);
      expect(await core.authDeviceId(serial: null, platformId: 'other'), id);

      // A fresh stored session needs no network.
      storage['mnemonic_mainWallet'] = _abandon;
      storage['jwt'] = _farFutureJwt;
      storage['refresh_token'] = 'rt';
      expect(await core.authAccessToken(), _farFutureJwt);
    },
    skip: library == null ? 'native library not built' : false,
  );

  test(
    'auth without secure storage throws invalidState',
    () async {
      final core = await openCore();
      await expectLater(
        core.authAccessToken(),
        throwsA(
          isA<CoreError>().having(
            (e) => e.kind,
            'kind',
            CoreErrorKind.invalidState,
          ),
        ),
      );
    },
    skip: library == null ? 'native library not built' : false,
  );

  test(
    'a throwing secure-storage callback becomes a storage CoreError',
    () async {
      final core = await openCore();
      await core.setSecureStorage(
        read: (key) async => throw StateError('keychain locked'),
        write: (key, value) async {},
        delete: (key) async {},
        listKeys: (prefix) async => <String>[],
      );
      await expectLater(
        core.secureGet(key: 'jwt'),
        throwsA(
          isA<CoreError>().having((e) => e.kind, 'kind', CoreErrorKind.storage),
        ),
      );
    },
    skip: library == null ? 'native library not built' : false,
  );

  test(
    'validates taxpayer ids and keeps favorite payers',
    () async {
      expect(taxIdIsValid(input: '529.982.247-25'), isTrue);
      expect(
        taxIdValidate(input: '111.111.111-11'),
        CpfValidationErrorDto.invalid,
      );
      expect(taxIdValidate(input: '529'), CpfValidationErrorDto.incomplete);
      expect(taxIdMaskInput(text: '52998224725'), '529.982.247-25');
      expect(pixLooksLikeKey(value: 'user@example.com'), isTrue);

      final core = await openCore();
      expect(
        await core.favoritePayerSave(label: ' Ana ', cpf: '529.982.247-25'),
        isNull,
      );
      expect(
        await core.favoritePayerSave(label: 'Bia', cpf: '52998224725'),
        FavoritePayerSaveErrorDto.duplicateCpf,
      );
      final payers = await core.favoritePayersList();
      expect(payers.single.label, 'Ana');
      expect(payers.single.cpf, '52998224725');
      expect(payers.single.maskedCpf, '529.982.247-25');
      expect(
        await core.favoritePayerCpfExists(
          cpf: '52998224725',
          excludingId: payers.single.id,
        ),
        isFalse,
      );
      await core.favoritePayerDelete(id: payers.single.id!);
      expect(await core.favoritePayersList(), isEmpty);

      expect(await core.pixFlagIsSet(flag: PixFlagDto.tutorialShown), isFalse);
      await core.pixFlagSet(flag: PixFlagDto.tutorialShown);
      expect(await core.pixFlagIsSet(flag: PixFlagDto.tutorialShown), isTrue);
    },
    skip: library == null ? 'native library not built' : false,
  );

  test(
    'sideswap calls before connect throw invalidState',
    () async {
      final core = await openCore();
      await expectLater(
        core.pegLimits(),
        throwsA(
          isA<CoreError>().having(
            (e) => e.kind,
            'kind',
            CoreErrorKind.invalidState,
          ),
        ),
      );
      expect(sideswapDefaultUrl(), startsWith('wss://'));
    },
    skip: library == null ? 'native library not built' : false,
  );
}
