import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/merchant/presentation/controllers/merchant_payment_link_controller.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_payment_link_repository.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// One recorded call of [_FakeLinkRepository].
typedef _Call = ({
  int amountInCents,
  Asset asset,
  String address,
  bool singleUse,
  String key,
});

/// Answers each call with the next queued result.
class _FakeLinkRepository implements PixPaymentLinkRepository {
  final List<Future<Either<PixHubFailure, PixPaymentLink>> Function()> results;
  final List<_Call> calls = [];

  _FakeLinkRepository(this.results);

  @override
  TaskEither<PixHubFailure, PixPaymentLink> createFixedAmountLink({
    required int amountInCents,
    required Asset asset,
    required String destinationAddress,
    required bool singleUse,
    required String idempotencyKey,
  }) {
    return TaskEither(() {
      calls.add((
        amountInCents: amountInCents,
        asset: asset,
        address: destinationAddress,
        singleUse: singleUse,
        key: idempotencyKey,
      ));
      return results.removeAt(0)();
    });
  }
}

final _link = PixPaymentLink(
  id: 'link-1',
  url: 'https://pay.mooze.app/pay/tok',
  reference: '',
  amountInCents: 4590,
  status: PixPaymentLinkStatus.pending,
  createdAt: DateTime(2026, 10, 21),
  singleUse: true,
);

Future<Either<PixHubFailure, PixPaymentLink>> Function() _ok() =>
    () async => Right(_link);

Future<Either<PixHubFailure, PixPaymentLink>> Function() _fail(
  PixHubErrorCode code,
) =>
    () async => Left(PixHubFailure(code));

void main() {
  const request = (amountInCents: 4590, asset: Asset.lbtc);

  late int addressCalls;
  late int keyCalls;
  late List<String> logs;

  MerchantPaymentLinkController controllerWith(
    _FakeLinkRepository repository, {
    List<Either<String, String>>? addresses,
  }) {
    final queue = addresses ?? [const Right('lq1qqaddress')];
    return MerchantPaymentLinkController(
      repository: repository,
      request: request,
      receiveAddress: () async {
        addressCalls++;
        return queue.length > 1 ? queue.removeAt(0) : queue.first;
      },
      newIdempotencyKey: () => 'key-${++keyCalls}',
      log: logs.add,
    );
  }

  setUp(() {
    addressCalls = 0;
    keyCalls = 0;
    logs = [];
  });

  test('creates a single-use link for the confirmed amount', () async {
    final repository = _FakeLinkRepository([_ok()]);
    final controller = controllerWith(repository);

    await controller.create();

    expect(controller.state.link, same(_link));
    expect(controller.state.isBusy, isFalse);
    expect(repository.calls.single, (
      amountInCents: 4590,
      asset: Asset.lbtc,
      address: 'lq1qqaddress',
      singleUse: true,
      key: 'key-1',
    ));
  });

  test('ignores a second call while the first one runs', () async {
    final pending = Completer<Either<PixHubFailure, PixPaymentLink>>();
    final repository = _FakeLinkRepository([() => pending.future]);
    final controller = controllerWith(repository);

    final first = controller.create();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.isBusy, isTrue);
    await controller.create();
    await controller.create();

    pending.complete(Right(_link));
    await first;

    expect(repository.calls, hasLength(1));
    expect(controller.state.link, same(_link));
  });

  test('a retry sends the same address and idempotency key', () async {
    final repository = _FakeLinkRepository([
      _fail(PixHubErrorCode.network),
      _ok(),
    ]);
    final controller = controllerWith(repository);

    await controller.create();
    expect(controller.state.failure?.code, PixHubErrorCode.network);
    await controller.create();

    expect(controller.state.link, same(_link));
    expect(repository.calls, hasLength(2));
    expect(repository.calls[1].key, repository.calls[0].key);
    expect(repository.calls[1].address, repository.calls[0].address);
    expect(addressCalls, 1);
    expect(keyCalls, 1);
  });

  test('does nothing after the link exists', () async {
    final repository = _FakeLinkRepository([_ok()]);
    final controller = controllerWith(repository);

    await controller.create();
    await controller.create();

    expect(repository.calls, hasLength(1));
  });

  test('a wallet without an address fails before the request', () async {
    final repository = _FakeLinkRepository([_ok()]);
    final controller = controllerWith(
      repository,
      addresses: [const Left('not connected'), const Right('lq1qqlater')],
    );

    await controller.create();
    expect(controller.state.failure?.code, PixHubErrorCode.walletUnavailable);
    expect(repository.calls, isEmpty);

    await controller.create();
    expect(repository.calls.single.address, 'lq1qqlater');
    expect(controller.state.link, same(_link));
  });

  group('logs', () {
    test('the start and the failure, with its code and cause', () async {
      final repository = _FakeLinkRepository([
        () async => const Left(
          PixHubFailure(
            PixHubErrorCode.serviceUnavailable,
            rawMessage: 'http 403 <!DOCTYPE html>',
          ),
        ),
      ]);
      final controller = controllerWith(repository);

      await controller.create();

      expect(logs.first, 'create start amount=4590 asset=lbtc retry=false');
      expect(
        logs.last,
        'create failed code=serviceUnavailable cause="http 403 <!DOCTYPE html>"',
      );
    });

    test('a wallet failure', () async {
      final controller = controllerWith(
        _FakeLinkRepository([]),
        addresses: [const Left('not connected')],
      );

      await controller.create();

      expect(logs, contains('receive address failed: not connected'));
    });

    test('a success', () async {
      final controller = controllerWith(_FakeLinkRepository([_ok()]));

      await controller.create();

      expect(logs.last, 'create ok id=link-1');
    });

    test('a throw ends as a failure, not as an endless load', () async {
      final repository = _FakeLinkRepository([
        () async => throw StateError('session store broken'),
      ]);
      final controller = controllerWith(repository);

      await controller.create();

      expect(controller.state.isBusy, isFalse);
      expect(controller.state.failure?.code, PixHubErrorCode.unknown);
      expect(
        logs.last,
        startsWith('create crashed: Bad state: session store broken at '),
      );
    });
  });
}
