import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart'
    show moozeCoreProvider;
import 'package:mooze_mobile/features/address_explorer/data/repositories/core_address_explorer_repository.dart';
import 'package:mooze_mobile/features/address_explorer/domain/repositories/address_explorer_repository.dart';
import 'package:mooze_mobile/features/address_explorer/domain/services/address_chain_detector.dart';
import 'package:mooze_mobile/features/address_explorer/domain/usecases/find_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/usecases/get_next_unused_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/usecases/list_addresses.dart';

final addressChainDetectorProvider =
    Provider<AddressChainDetector>((ref) => const AddressChainDetector());

final addressExplorerRepositoryProvider =
    FutureProvider<Either<String, AddressExplorerRepository>>((ref) async {
  // An open failure becomes a Left.
  try {
    final core = await ref.watch(moozeCoreProvider.future);
    return Either.right(CoreAddressExplorerRepository(core: core));
  } catch (e) {
    return Either.left(e.toString());
  }
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
