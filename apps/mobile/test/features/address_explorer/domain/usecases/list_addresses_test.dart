import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_status.dart';
import 'package:mooze_mobile/features/address_explorer/domain/repositories/address_explorer_repository.dart';
import 'package:mooze_mobile/features/address_explorer/domain/usecases/list_addresses.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

class _MockRepository extends Mock implements AddressExplorerRepository {}

void main() {
  late _MockRepository repo;
  late ListAddresses useCase;

  setUp(() {
    repo = _MockRepository();
    useCase = ListAddresses(repo);
  });

  WalletAddress addr(int i, AddressChain chain) => WalletAddress(
        address: 'addr-$i',
        chain: chain,
        status: AddressStatus.unused,
        derivationIndex: i,
      );

  test('routes to Bitcoin repository for bitcoin chain', () async {
    final addresses = [
      addr(0, AddressChain.bitcoin),
      addr(1, AddressChain.bitcoin),
    ];
    when(() => repo.listBitcoinAddresses(limit: 50))
        .thenAnswer((_) => TaskEither.right(addresses));

    final result =
        await useCase.call(chain: AddressChain.bitcoin, limit: 50).run();

    expect(result.getRight().toNullable(), addresses);
    verify(() => repo.listBitcoinAddresses(limit: 50)).called(1);
    verifyNever(() => repo.listLiquidAddresses(limit: any(named: 'limit')));
  });

  test('routes to Liquid repository for liquid chain', () async {
    final addresses = [addr(0, AddressChain.liquid)];
    when(() => repo.listLiquidAddresses(limit: 100))
        .thenAnswer((_) => TaskEither.right(addresses));

    final result = await useCase.call(chain: AddressChain.liquid).run();

    expect(result.getRight().toNullable(), addresses);
    verify(() => repo.listLiquidAddresses(limit: 100)).called(1);
  });

  test('propagates failures from the repository', () async {
    when(() => repo.listBitcoinAddresses(limit: 100)).thenAnswer(
      (_) => TaskEither.left(const WalletError(WalletErrorType.sdkError)),
    );

    final result = await useCase.call(chain: AddressChain.bitcoin).run();

    expect(result.isLeft(), true);
  });
}
