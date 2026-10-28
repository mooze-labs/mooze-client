import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart'
    show liquidWalletServiceProvider;
import 'package:mooze_mobile/features/pix/hub/data/pix_api_log.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_payment_link_repository.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_api_log_sink.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:uuid/uuid.dart';

/// The sale that a payment link charges: the confirmed amount and the asset
/// the merchant receives.
typedef MerchantPaymentLinkRequest = ({int amountInCents, Asset asset});

/// State of the payment-link step of a sale.
class MerchantPaymentLinkState {
  final bool isBusy;
  final PixPaymentLink? link;
  final PixHubFailure? failure;

  const MerchantPaymentLinkState({
    this.isBusy = false,
    this.link,
    this.failure,
  });
}

/// Creates the payment link of one sale.
///
/// One controller serves one attempt. The receive address and the
/// idempotency key are kept after a failure, so a retry repeats the same
/// request and the API cannot create a second link for the sale.
///
/// Every step writes a [paymentLinkLogKey] log line, so a search for that key
/// in the debug console shows why a link failed.
class MerchantPaymentLinkController
    extends StateNotifier<MerchantPaymentLinkState> {
  MerchantPaymentLinkController({
    required PixPaymentLinkRepository repository,
    required Future<Either<String, String>> Function() receiveAddress,
    required this.request,
    String Function()? newIdempotencyKey,
    void Function(String message)? log,
  }) : _repository = repository,
       _receiveAddress = receiveAddress,
       _newIdempotencyKey = newIdempotencyKey ?? const Uuid().v4,
       _log = log ?? _ignore,
       super(const MerchantPaymentLinkState());

  final MerchantPaymentLinkRequest request;
  final PixPaymentLinkRepository _repository;
  final Future<Either<String, String>> Function() _receiveAddress;
  final String Function() _newIdempotencyKey;
  final void Function(String message) _log;

  static void _ignore(String _) {}

  String? _address;
  String? _idempotencyKey;

  /// Creates the link. A call while a request runs, or after the link
  /// exists, does nothing.
  Future<void> create() async {
    if (state.isBusy || state.link != null) return;
    state = const MerchantPaymentLinkState(isBusy: true);
    _log(
      'create start amount=${request.amountInCents} '
      'asset=${EnumName(request.asset).name} '
      'retry=${_idempotencyKey != null}',
    );

    try {
      final address = _address ?? await _loadAddress();
      if (address == null) return;
      final key = _idempotencyKey ??= _newIdempotencyKey();

      final result = await _repository
          .createFixedAmountLink(
            amountInCents: request.amountInCents,
            asset: request.asset,
            destinationAddress: address,
            // A merchant sale takes one payment.
            singleUse: true,
            idempotencyKey: key,
          )
          .run();
      if (!mounted) return;

      state = result.fold(
        (failure) {
          _log(
            'create failed code=${failure.code.name} '
            'cause="${logSnippet(failure.rawMessage)}"',
          );
          return MerchantPaymentLinkState(failure: failure);
        },
        (link) {
          _log('create ok id=${link.id}');
          return MerchantPaymentLinkState(link: link);
        },
      );
    } catch (error, stackTrace) {
      // A throw would leave the sale screen on its loading overlay. Report it
      // as a failure, so the screen can offer a retry.
      final frames = stackTrace.toString().split('\n').take(3).join(' | ');
      _log('create crashed: ${logSnippet('$error')} at $frames');
      if (!mounted) return;
      state = MerchantPaymentLinkState(
        failure: PixHubFailure(PixHubErrorCode.unknown, rawMessage: '$error'),
      );
    }
  }

  /// Reads a new receive address. On failure it sets the failure state and
  /// returns null.
  Future<String?> _loadAddress() async {
    final result = await _receiveAddress();
    if (!mounted) return null;
    return result.fold((message) {
      _log('receive address failed: ${logSnippet(message)}');
      state = MerchantPaymentLinkState(
        failure: PixHubFailure(
          PixHubErrorCode.walletUnavailable,
          rawMessage: message,
        ),
      );
      return null;
    }, (address) => _address = address);
  }
}

/// The payment-link step of one sale.
///
/// The receive address comes from the Liquid wallet, as a bare address:
/// the API expects an Elements address, not a `liquidnetwork:` URI.
final merchantPaymentLinkControllerProvider = StateNotifierProvider.autoDispose
    .family<
      MerchantPaymentLinkController,
      MerchantPaymentLinkState,
      MerchantPaymentLinkRequest
    >((ref, request) {
      final wallet = ref.read(liquidWalletServiceProvider);
      return MerchantPaymentLinkController(
        repository: ref.watch(pixPaymentLinkRepositoryProvider),
        request: request,
        log: pixApiLogSink(ref, paymentLinkLogKey),
        receiveAddress: () async {
          // No asset id: the service returns a bare address.
          final result = await wallet.nextReceiveAddress();
          return result.fold((failure) => Left(failure.message), (receive) {
            final address = receive.address;
            return address == null || address.isEmpty
                ? const Left('empty receive address')
                : Right(address);
          });
        },
      );
    });
