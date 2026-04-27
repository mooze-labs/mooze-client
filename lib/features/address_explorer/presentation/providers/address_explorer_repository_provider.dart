import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/address_explorer/data/repositories/address_explorer_repository_impl.dart';
import 'package:mooze_mobile/features/address_explorer/domain/repositories/address_explorer_repository.dart';
import 'package:mooze_mobile/features/address_explorer/domain/services/address_chain_detector.dart';
import 'package:mooze_mobile/features/address_explorer/domain/usecases/find_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/usecases/get_next_unused_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/usecases/list_addresses.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/lwk/providers/datasource_provider.dart';

final addressChainDetectorProvider =
    Provider<AddressChainDetector>((ref) => const AddressChainDetector());

final addressExplorerRepositoryProvider =
    FutureProvider<Either<String, AddressExplorerRepository>>((ref) async {
  final bdk = await ref.watch(bdkDatasourceProvider.future);
  final lwk = await ref.watch(liquidDataSourceProvider.future);

  return bdk.flatMap(
    (bdkDs) => lwk.map(
      (lwkDs) => AddressExplorerRepositoryImpl(bdk: bdkDs, lwk: lwkDs),
    ),
  );
});

final findAddressUseCaseProvider =
    FutureProvider<Either<String, FindAddress>>((ref) async {
  final repo = await ref.watch(addressExplorerRepositoryProvider.future);
  final detector = ref.watch(addressChainDetectorProvider);
  return repo.map((r) => FindAddress(r, detector));
});

final listAddressesUseCaseProvider =
    FutureProvider<Either<String, ListAddresses>>((ref) async {
  final repo = await ref.watch(addressExplorerRepositoryProvider.future);
  return repo.map((r) => ListAddresses(r));
});

final getNextUnusedAddressUseCaseProvider =
    FutureProvider<Either<String, GetNextUnusedAddress>>((ref) async {
  final repo = await ref.watch(addressExplorerRepositoryProvider.future);
  return repo.map((r) => GetNextUnusedAddress(r));
});
