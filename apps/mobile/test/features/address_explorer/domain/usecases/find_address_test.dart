import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_match.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_utxo.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_status.dart';
import 'package:mooze_mobile/features/address_explorer/domain/repositories/address_explorer_repository.dart';
import 'package:mooze_mobile/features/address_explorer/domain/services/address_chain_detector.dart';
import 'package:mooze_mobile/features/address_explorer/domain/usecases/find_address.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

class _MockRepository extends Mock implements AddressExplorerRepository {}

void main() {
  late _MockRepository repo;
  late FindAddress useCase;

  setUp(() {
    repo = _MockRepository();
    useCase = FindAddress(repo, const AddressChainDetector());
  });

  TaskEither<WalletError, AddressMatch> notOwned(String address) =>
      TaskEither.right(AddressMatch.notOwned(address));

  TaskEither<WalletError, AddressMatch> ownedAs({
    required String address,
    required AddressChain chain,
    AddressStatus status = AddressStatus.unused,
    int? index,
  }) =>
      TaskEither.right(AddressMatch.owned(
        address: address,
        chain: chain,
        status: status,
        derivationIndex: index,
      ));

  test('returns invalidAddress failure on empty input', () async {
    final result = await useCase.call('   ').run();
    expect(result.isLeft(), true);
    final err = result.getLeft().toNullable();
    expect(err?.type, WalletErrorType.invalidAddress);
  });

  test('probes only Bitcoin for bc1 prefix', () async {
    const addr = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';
    when(() => repo.isOwnedBitcoinAddress(addr))
        .thenAnswer((_) => ownedAs(address: addr, chain: AddressChain.bitcoin));

    final result = await useCase.call(addr).run();

    expect(result.isRight(), true);
    final match = result.getRight().toNullable();
    expect(match?.isOwned, true);
    expect(match?.chain, AddressChain.bitcoin);
    verifyNever(() => repo.isOwnedLiquidAddress(any()));
  });

  test('probes only Liquid for lq1 prefix', () async {
    const addr = 'lq1qqg5acpr3ekg26ppwxh4z4qe9hsh';
    when(() => repo.isOwnedLiquidAddress(addr))
        .thenAnswer((_) => ownedAs(address: addr, chain: AddressChain.liquid));

    final result = await useCase.call(addr).run();

    expect(result.getRight().toNullable()?.chain, AddressChain.liquid);
    verifyNever(() => repo.isOwnedBitcoinAddress(any()));
  });

  test('strips bitcoin: URI scheme before probing', () async {
    const addr = 'bc1qabc';
    when(() => repo.isOwnedBitcoinAddress(addr))
        .thenAnswer((_) => ownedAs(address: addr, chain: AddressChain.bitcoin));

    final result = await useCase.call('bitcoin:$addr?amount=0.5').run();

    expect(result.getRight().toNullable()?.isOwned, true);
    verify(() => repo.isOwnedBitcoinAddress(addr)).called(1);
  });

  test('falls back to Liquid when Bitcoin probe says not owned (ambiguous prefix)', () async {
    const addr = 'zzzunknownprefix123';
    when(() => repo.isOwnedBitcoinAddress(addr))
        .thenAnswer((_) => notOwned(addr));
    when(() => repo.isOwnedLiquidAddress(addr))
        .thenAnswer((_) => ownedAs(address: addr, chain: AddressChain.liquid));

    final result = await useCase.call(addr).run();

    expect(result.getRight().toNullable()?.chain, AddressChain.liquid);
    verify(() => repo.isOwnedBitcoinAddress(addr)).called(1);
    verify(() => repo.isOwnedLiquidAddress(addr)).called(1);
  });

  test('returns notOwned when no chain claims the address', () async {
    const addr = 'zzzunknownprefix123';
    when(() => repo.isOwnedBitcoinAddress(addr))
        .thenAnswer((_) => notOwned(addr));
    when(() => repo.isOwnedLiquidAddress(addr))
        .thenAnswer((_) => notOwned(addr));

    final result = await useCase.call(addr).run();

    final match = result.getRight().toNullable();
    expect(match?.isOwned, false);
    expect(match?.address, addr);
  });

  test('propagates repository failure', () async {
    const addr = 'bc1qabc';
    const failure = WalletError(WalletErrorType.connectionError);
    when(() => repo.isOwnedBitcoinAddress(addr))
        .thenAnswer((_) => TaskEither.left(failure));

    final result = await useCase.call(addr).run();

    expect(result.isLeft(), true);
    expect(result.getLeft().toNullable()?.type,
        WalletErrorType.connectionError);
  });
}

// Suppress unused-import lint when no UTXO usage in this file; kept for
// symmetry with other tests that share fixtures.
// ignore: unused_element
WalletAddress _exampleAddress() => WalletAddress(
      address: 'bc1qabc',
      chain: AddressChain.bitcoin,
      status: AddressStatus.unused,
      derivationIndex: 0,
      utxos: const <AddressUtxo>[],
    );
