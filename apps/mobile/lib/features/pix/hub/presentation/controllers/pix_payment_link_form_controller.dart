import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_payment_link_reference_store.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_payment_link_repository.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:uuid/uuid.dart';

/// State of the payment-link form.
class PixPaymentLinkFormState {
  final PixPaymentLink? created;
  final bool isBusy;
  final PixHubFailure? failure;

  const PixPaymentLinkFormState({
    this.created,
    this.isBusy = false,
    this.failure,
  });
}

/// The inputs that the API binds to one idempotency key.
typedef _Charge = ({int amountInCents, Asset asset, bool singleUse});

/// Creates payment links through the payment-link API.
///
/// The link pays a new receive address of the wallet. The address and the
/// idempotency key survive a failure, so a retry of the same charge cannot
/// create a second link when the first answer was lost. The reference stays
/// on the device, because the API has no field for it.
class PixPaymentLinkFormController
    extends StateNotifier<PixPaymentLinkFormState> {
  PixPaymentLinkFormController({
    required PixPaymentLinkRepository repository,
    required PixPaymentLinkReferenceStore references,
    required Future<Either<String, String>> Function() receiveAddress,
    String Function()? newIdempotencyKey,
  }) : _repository = repository,
       _references = references,
       _receiveAddress = receiveAddress,
       _newIdempotencyKey = newIdempotencyKey ?? const Uuid().v4,
       super(const PixPaymentLinkFormState());

  final PixPaymentLinkRepository _repository;
  final PixPaymentLinkReferenceStore _references;
  final Future<Either<String, String>> Function() _receiveAddress;
  final String Function() _newIdempotencyKey;

  String? _address;
  _Charge? _charge;
  String? _idempotencyKey;

  void reset() => state = const PixPaymentLinkFormState();

  /// Creates a link that charges [amountInCents].
  ///
  /// The [reference] is optional: it only organizes the links of the owner.
  /// An empty one keeps nothing on the device, and the link shows a generic
  /// name.
  Future<PixPaymentLink?> create({
    String reference = '',
    required bool singleUse,
    required Asset asset,
    required int amountInCents,
  }) async {
    if (state.isBusy) return null;
    state = const PixPaymentLinkFormState(isBusy: true);

    final address = _address ?? await _loadAddress();
    if (address == null) return null;

    // The API refuses one key with other inputs, so another charge gets a
    // new key.
    final charge = (
      amountInCents: amountInCents,
      asset: asset,
      singleUse: singleUse,
    );
    if (_charge != charge) {
      _charge = charge;
      _idempotencyKey = _newIdempotencyKey();
    }

    final result = await _repository
        .createFixedAmountLink(
          amountInCents: amountInCents,
          asset: asset,
          destinationAddress: address,
          singleUse: singleUse,
          idempotencyKey: _idempotencyKey!,
        )
        .run();
    if (!mounted) return null;

    final link = result.toNullable();
    if (link == null) {
      state = PixPaymentLinkFormState(failure: result.getLeft().toNullable());
      return null;
    }

    // The link exists even when the reference cannot be stored.
    if (reference.isNotEmpty) {
      try {
        await _references.save(link.id, reference);
      } catch (_) {}
    }
    final named = link.withReference(reference);
    if (mounted) state = PixPaymentLinkFormState(created: named);
    return named;
  }

  /// Reads a new receive address. On failure it sets the failure state and
  /// returns null.
  Future<String?> _loadAddress() async {
    final result = await _receiveAddress();
    if (!mounted) return null;
    return result.fold((message) {
      state = PixPaymentLinkFormState(
        failure: PixHubFailure(
          PixHubErrorCode.walletUnavailable,
          rawMessage: message,
        ),
      );
      return null;
    }, (address) => _address = address);
  }
}
