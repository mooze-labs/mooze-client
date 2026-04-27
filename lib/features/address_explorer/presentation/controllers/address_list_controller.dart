import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/providers/address_explorer_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

/// Initial number of derivation indices scanned per chain.
const int kAddressInitialPageSize = 50;

/// Increment applied each time the user taps "load more".
const int kAddressLoadMoreSize = 50;

/// Tracks the current scan limit per chain. Tapping "load more" bumps the
/// integer by [kAddressLoadMoreSize], which causes the dependent FutureProvider
/// below to re-run with the new limit.
final addressScanLimitProvider =
    StateProvider.autoDispose.family<int, AddressChain>(
  (ref, _) => kAddressInitialPageSize,
);

/// Resolves to the current scanned address list for [chain]. Returns the
/// previous value while a re-scan is in flight so the UI can keep showing
/// loaded rows under a "loading more" footer.
final addressListProvider = FutureProvider.autoDispose
    .family<List<WalletAddress>, AddressChain>((ref, chain) async {
  final limit = ref.watch(addressScanLimitProvider(chain));
  final useCaseEither =
      await ref.watch(listAddressesUseCaseProvider.future);

  return useCaseEither.match(
    (err) => throw WalletError(WalletErrorType.sdkError, err),
    (useCase) async {
      final result = await useCase.call(chain: chain, limit: limit).run();
      return result.match(
        (failure) => throw failure,
        (addresses) => addresses,
      );
    },
  );
});
