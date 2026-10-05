import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_status.dart';
import 'package:mooze_mobile/features/address_explorer/domain/repositories/address_explorer_repository.dart';
import 'package:mooze_mobile/features/address_explorer/domain/usecases/get_next_unused_address.dart';

class _MockRepository extends Mock implements AddressExplorerRepository {}

void main() {
  late _MockRepository repo;
  late GetNextUnusedAddress useCase;

  setUp(() {
    repo = _MockRepository();
    useCase = GetNextUnusedAddress(repo);
  });

  test('routes to Bitcoin repository for bitcoin chain', () async {
    final addr = WalletAddress(
      address: 'bc1qabc',
      chain: AddressChain.bitcoin,
      status: AddressStatus.unused,
      derivationIndex: 7,
    );
    when(() => repo.getNextUnusedBitcoinAddress())
        .thenAnswer((_) => TaskEither.right(addr));

    final result = await useCase.call(AddressChain.bitcoin).run();

    expect(result.getRight().toNullable()?.address, 'bc1qabc');
    expect(result.getRight().toNullable()?.derivationIndex, 7);
    verify(() => repo.getNextUnusedBitcoinAddress()).called(1);
    verifyNever(() => repo.getNextUnusedLiquidAddress());
  });

  test('routes to Liquid repository for liquid chain', () async {
    final addr = WalletAddress(
      address: 'lq1qabc',
      chain: AddressChain.liquid,
      status: AddressStatus.unused,
      derivationIndex: 3,
    );
    when(() => repo.getNextUnusedLiquidAddress())
        .thenAnswer((_) => TaskEither.right(addr));

    final result = await useCase.call(AddressChain.liquid).run();

    expect(result.getRight().toNullable()?.chain, AddressChain.liquid);
    verify(() => repo.getNextUnusedLiquidAddress()).called(1);
  });
}
