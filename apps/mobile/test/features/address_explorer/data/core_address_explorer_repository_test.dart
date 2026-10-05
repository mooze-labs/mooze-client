import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/features/address_explorer/data/repositories/core_address_explorer_repository.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_status.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

class _MockCore extends Mock implements MoozeCore {}

const _btc0 = 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu';
const _btc1 = 'bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g';
const _change0 = 'bc1q8c6fshw2dlwun7ekn9qwf37cu2rn755upcp6el';

DerivedAddressDto _addr(
  int index,
  String address, {
  KeychainDto keychain = KeychainDto.external_,
  String? unconfidential,
  bool used = false,
}) => DerivedAddressDto(
  keychain: keychain,
  index: index,
  address: address,
  unconfidential: unconfidential,
  scriptHex: 's-${unconfidential ?? address}',
  used: used,
);

WalletUtxoDto _utxo(
  String address, {
  required String txid,
  int vout = 0,
  int amount = 1000,
  KeychainDto keychain = KeychainDto.external_,
  int index = 0,
  String? unconfidential,
  String? assetId,
  int? height,
}) => WalletUtxoDto(
  txid: txid,
  vout: vout,
  address: address,
  unconfidential: unconfidential,
  scriptHex: 's-${unconfidential ?? address}',
  keychain: keychain,
  index: index,
  amountSat: BigInt.from(amount),
  assetId: assetId,
  confirmationHeight: height,
  confirmationTimeS: null,
);

CoreError _coreError(CoreErrorKind kind, String message) =>
    CoreError(kind: kind, message: message);

void main() {
  setUpAll(() {
    registerFallbackValue(KeychainDto.external_);
  });

  late _MockCore core;
  late CoreAddressExplorerRepository repo;

  setUp(() {
    core = _MockCore();
    repo = CoreAddressExplorerRepository(core: core);
  });

  void stubBtcDerived(
    KeychainDto keychain,
    int start,
    int count,
    List<DerivedAddressDto> result,
  ) {
    when(
      () => core.bitcoinDerivedAddresses(
        keychain: keychain,
        start: start,
        count: count,
      ),
    ).thenAnswer((_) async => result);
  }

  void stubLqDerived(int start, int count, List<DerivedAddressDto> result) {
    when(
      () => core.liquidDerivedAddresses(
        keychain: KeychainDto.external_,
        start: start,
        count: count,
      ),
    ).thenAnswer((_) async => result);
  }

  group('bitcoin', () {
    test('listBitcoinAddresses groups UTXOs and marks history', () async {
      stubBtcDerived(KeychainDto.external_, 0, 3, [
        _addr(0, _btc0, used: true),
        _addr(1, _btc1, used: true),
        _addr(2, 'bc1qthird'),
      ]);
      when(() => core.bitcoinUnspentOutputs()).thenAnswer(
        (_) async => [
          _utxo(_btc0, txid: 'a', amount: 10, height: 800000),
          _utxo(_btc0, txid: 'b', vout: 2, amount: 5),
          _utxo(
            _change0,
            txid: 'c',
            keychain: KeychainDto.internal,
            amount: 99,
          ),
        ],
      );

      final r = await repo.listBitcoinAddresses(limit: 3).run();
      final list = r.getOrElse((_) => <WalletAddress>[]);

      expect(list.map((a) => a.derivationIndex), [0, 1, 2]);
      expect(list[0].address, _btc0);
      expect(list[0].status, AddressStatus.used);
      expect(list[0].receivedSats, BigInt.from(15));
      expect(list[0].utxos.map((u) => u.outpoint), ['a:0', 'b:2']);
      expect(
        list[0].utxos.every((u) => u.confirmed && u.assetId == null),
        isTrue,
      );
      expect(list[0].utxos.first.chain, AddressChain.bitcoin);
      // Used from history, no UTXO left.
      expect(list[1].status, AddressStatus.used);
      expect(list[1].utxos, isEmpty);
      expect(list[1].receivedSats, BigInt.zero);
      expect(list[2].status, AddressStatus.unused);
    });

    test('a negative limit asks for no addresses', () async {
      stubBtcDerived(KeychainDto.external_, 0, 0, []);
      when(() => core.bitcoinUnspentOutputs()).thenAnswer((_) async => []);
      final r = await repo.listBitcoinAddresses(limit: -1).run();
      expect(r.getOrElse((_) => [_dummy()]), isEmpty);
    });

    test('listBitcoinUtxos keeps the old empty address for change', () async {
      when(() => core.bitcoinUnspentOutputs()).thenAnswer(
        (_) async => [
          _utxo(_btc0, txid: 'a', amount: 7),
          _utxo(_change0, txid: 'b', keychain: KeychainDto.internal),
          _utxo('bc1qfar', txid: 'c', index: 100),
        ],
      );
      final r = await repo.listBitcoinUtxos().run();
      final utxos = r.getOrElse((_) => []);
      expect(utxos.map((u) => u.address), [_btc0, '', '']);
      expect(utxos.first.outpoint, 'a:0');
      expect(utxos.first.value, BigInt.from(7));
    });

    test('isOwnedBitcoinAddress reports index, history and UTXOs', () async {
      when(() => core.bitcoinIsMine(address: _btc1)).thenAnswer(
        (_) async => const AddressOwnershipDto(
          keychain: KeychainDto.external_,
          index: 1,
        ),
      );
      stubBtcDerived(KeychainDto.external_, 1, 1, [_addr(1, _btc1)]);
      when(() => core.bitcoinUnspentOutputs()).thenAnswer(
        (_) async => [
          _utxo(_btc1, txid: 'x', index: 1, amount: 3),
          _utxo(_btc0, txid: 'y'),
        ],
      );

      final m = (await repo.isOwnedBitcoinAddress(_btc1).run()).getOrElse(
        (_) => throw StateError('left'),
      );
      expect(m.isOwned, isTrue);
      expect(m.chain, AddressChain.bitcoin);
      expect(m.derivationIndex, 1);
      // As before: "used" follows the history only, not the UTXOs.
      expect(m.status, AddressStatus.unused);
      expect(m.utxoCount, 1);
      expect(m.utxos.single.address, _btc1);
    });

    test('a change address is owned without an index', () async {
      when(() => core.bitcoinIsMine(address: _change0)).thenAnswer(
        (_) async =>
            const AddressOwnershipDto(keychain: KeychainDto.internal, index: 0),
      );
      stubBtcDerived(KeychainDto.internal, 0, 1, [
        _addr(0, _change0, keychain: KeychainDto.internal, used: true),
      ]);
      when(() => core.bitcoinUnspentOutputs()).thenAnswer((_) async => []);

      final m = (await repo.isOwnedBitcoinAddress(_change0).run()).getOrElse(
        (_) => throw StateError('left'),
      );
      expect(m.isOwned, isTrue);
      expect(m.derivationIndex, isNull);
      expect(m.status, AddressStatus.used);
    });

    test('not mine and core errors are "not owned"', () async {
      when(
        () => core.bitcoinIsMine(address: 'bc1qother'),
      ).thenAnswer((_) async => null);
      when(() => core.bitcoinIsMine(address: 'garbage')).thenThrow(
        _coreError(CoreErrorKind.invalidInput, 'invalid bitcoin address'),
      );

      for (final a in ['bc1qother', 'garbage']) {
        final m = (await repo.isOwnedBitcoinAddress(a).run()).getOrElse(
          (_) => throw StateError('left'),
        );
        expect(m.isOwned, isFalse);
        expect(m.address, a);
      }
    });

    test('getNextUnusedBitcoinAddress maps the core result', () async {
      when(() => core.bitcoinNextUnusedAddress()).thenAnswer(
        (_) async =>
            const NextUnusedAddressDto(index: 4, address: _btc1, used: false),
      );
      final a = (await repo.getNextUnusedBitcoinAddress().run()).getOrElse(
        (_) => throw StateError('left'),
      );
      expect(a.address, _btc1);
      expect(a.derivationIndex, 4);
      expect(a.status, AddressStatus.unused);
      expect(a.chain, AddressChain.bitcoin);
    });

    test('core errors become sdkError WalletErrors', () async {
      when(() => core.bitcoinNextUnusedAddress()).thenThrow(
        _coreError(
          CoreErrorKind.invalidState,
          'invalid state: bitcoin wallet not connected',
        ),
      );
      final r = await repo.getNextUnusedBitcoinAddress().run();
      final err = r.getLeft().toNullable()!;
      expect(err.type, WalletErrorType.sdkError);
      expect(err.customDescription, contains('bitcoin wallet not connected'));
    });
  });

  group('liquid', () {
    final lq0 = _addr(0, 'lq1zero', unconfidential: 'ex1zero', used: true);
    final lq1 = _addr(1, 'lq1one', unconfidential: 'ex1one');

    test(
      'listLiquidAddresses groups UTXOs by unconfidential address',
      () async {
        stubLqDerived(0, 2, [lq0, lq1]);
        when(() => core.liquidUnspentOutputs()).thenAnswer(
          (_) async => [
            _utxo(
              'lq1zero',
              txid: 't',
              unconfidential: 'ex1zero',
              amount: 50,
              assetId: 'A',
            ),
            _utxo(
              'lq1one',
              txid: 'u',
              unconfidential: 'ex1one',
              amount: 7,
              assetId: 'B',
            ),
          ],
        );
        final list = (await repo.listLiquidAddresses(limit: 2).run()).getOrElse(
          (_) => [],
        );
        expect(list.map((a) => a.address), ['lq1zero', 'lq1one']);
        expect(list.every((a) => a.status == AddressStatus.used), isTrue);
        expect(list[0].utxos.single.assetId, 'A');
        expect(list[0].utxos.single.chain, AddressChain.liquid);
        expect(list[1].receivedSats, BigInt.from(7));
      },
    );

    test('listLiquidUtxos lists every output with its asset', () async {
      when(() => core.liquidUnspentOutputs()).thenAnswer(
        (_) async => [
          _utxo(
            'lq1zero',
            txid: 't',
            vout: 1,
            unconfidential: 'ex1zero',
            assetId: 'A',
          ),
        ],
      );
      final utxos = (await repo.listLiquidUtxos().run()).getOrElse((_) => []);
      expect(utxos.single.address, 'lq1zero');
      expect(utxos.single.outpoint, 't:1');
      expect(utxos.single.assetId, 'A');
    });

    test('isOwnedLiquidAddress scans 200 and reports used', () async {
      when(
        () => core.liquidIsMine(address: 'ex1one', scanLimit: 200),
      ).thenAnswer(
        (_) async => const AddressOwnershipDto(
          keychain: KeychainDto.external_,
          index: 1,
        ),
      );
      stubLqDerived(1, 1, [lq1]);
      when(() => core.liquidUnspentOutputs()).thenAnswer(
        (_) async => [
          _utxo('lq1one', txid: 'u', unconfidential: 'ex1one', amount: 9),
        ],
      );
      final m = (await repo.isOwnedLiquidAddress('ex1one').run()).getOrElse(
        (_) => throw StateError('left'),
      );
      expect(m.isOwned, isTrue);
      expect(m.chain, AddressChain.liquid);
      expect(m.derivationIndex, 1);
      expect(m.status, AddressStatus.used);
      expect(m.utxos.single.address, 'ex1one');
    });

    test('change addresses, misses and errors are "not owned"', () async {
      when(
        () => core.liquidIsMine(address: 'lq1change', scanLimit: 200),
      ).thenAnswer(
        (_) async =>
            const AddressOwnershipDto(keychain: KeychainDto.internal, index: 0),
      );
      when(
        () => core.liquidIsMine(address: 'lq1other', scanLimit: 200),
      ).thenAnswer((_) async => null);
      when(
        () => core.liquidIsMine(address: 'bad', scanLimit: 200),
      ).thenThrow(_coreError(CoreErrorKind.invalidInput, 'bad'));
      for (final a in ['lq1change', 'lq1other', 'bad']) {
        final m = (await repo.isOwnedLiquidAddress(a).run()).getOrElse(
          (_) => throw StateError('left'),
        );
        expect(m.isOwned, isFalse, reason: a);
      }
    });

    test('getNextUnusedLiquidAddress keeps the history flag', () async {
      when(() => core.liquidNextUnusedAddress()).thenAnswer(
        (_) async =>
            const NextUnusedAddressDto(index: 2, address: 'lq1two', used: true),
      );
      final a = (await repo.getNextUnusedLiquidAddress().run()).getOrElse(
        (_) => throw StateError('left'),
      );
      expect(a.address, 'lq1two');
      expect(a.derivationIndex, 2);
      expect(a.status, AddressStatus.used);
      expect(a.chain, AddressChain.liquid);
    });
  });
}

WalletAddress _dummy() => WalletAddress(
  address: 'x',
  chain: AddressChain.bitcoin,
  status: AddressStatus.unused,
  derivationIndex: 0,
);
