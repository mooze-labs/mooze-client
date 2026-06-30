import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_match.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/providers/address_explorer_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

class AddressOwnershipState {
  final bool isLoading;
  final AddressMatch? match;
  final WalletError? error;

  const AddressOwnershipState({
    this.isLoading = false,
    this.match,
    this.error,
  });

  const AddressOwnershipState.idle() : this();
  const AddressOwnershipState.loading() : this(isLoading: true);
  const AddressOwnershipState.success(AddressMatch result)
      : this(match: result);
  const AddressOwnershipState.failure(WalletError err) : this(error: err);
}

class AddressOwnershipController
    extends AutoDisposeNotifier<AddressOwnershipState> {
  @override
  AddressOwnershipState build() => const AddressOwnershipState.idle();

  Future<void> verify(String input) async {
    if (input.trim().isEmpty) {
      state = const AddressOwnershipState.idle();
      return;
    }

    state = const AddressOwnershipState.loading();

    final useCaseEither =
        await ref.read(findAddressUseCaseProvider.future);

    await useCaseEither.match(
      (err) async {
        state = AddressOwnershipState.failure(
          WalletError(WalletErrorType.sdkError, err),
        );
      },
      (useCase) async {
        final result = await useCase.call(input).run();
        state = result.match(
          (failure) => AddressOwnershipState.failure(failure),
          (match) => AddressOwnershipState.success(match),
        );
      },
    );
  }

  void reset() {
    state = const AddressOwnershipState.idle();
  }
}

final addressOwnershipControllerProvider = AutoDisposeNotifierProvider<
    AddressOwnershipController, AddressOwnershipState>(
  AddressOwnershipController.new,
);
