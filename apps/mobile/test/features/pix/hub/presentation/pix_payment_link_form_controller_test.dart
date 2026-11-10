import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_payment_link_reference_store.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_payment_link_repository.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/controllers/pix_payment_link_form_controller.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _Create = ({
  int? amountInCents,
  Asset asset,
  String address,
  bool singleUse,
  String key,
});

/// Answers each create with the next queued result.
class _FakeLinks implements PixPaymentLinkRepository {
  final List<Either<PixHubFailure, PixPaymentLink>> answers;
  final List<_Create> creates = [];

  _FakeLinks(this.answers);

  @override
  TaskEither<PixHubFailure, PixPaymentLink> createLink({
    int? amountInCents,
    required Asset asset,
    required String destinationAddress,
    required bool singleUse,
    required String idempotencyKey,
  }) {
    creates.add((
      amountInCents: amountInCents,
      asset: asset,
      address: destinationAddress,
      singleUse: singleUse,
      key: idempotencyKey,
    ));
    return TaskEither.fromEither(answers.removeAt(0));
  }

  @override
  TaskEither<PixHubFailure, PixPaymentLink> createFixedAmountLink({
    required int amountInCents,
    required Asset asset,
    required String destinationAddress,
    required bool singleUse,
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  TaskEither<PixHubFailure, List<PixPaymentLink>> listLinks() =>
      throw UnimplementedError();

  @override
  TaskEither<PixHubFailure, Unit> revokeLink(String id) =>
      throw UnimplementedError();
}

final _link = PixPaymentLink(
  id: 'link-1',
  url: 'https://pay.mooze.app/pay/tok',
  reference: '',
  status: PixPaymentLinkStatus.pending,
  createdAt: DateTime.utc(2026, 11, 5),
  singleUse: true,
  amountInCents: 4590,
  asset: Asset.depix,
);

const _refused = Left<PixHubFailure, PixPaymentLink>(
  PixHubFailure(PixHubErrorCode.serviceUnavailable),
);

void main() {
  late PixPaymentLinkReferenceStore references;
  late int addressReads;
  late int keys;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    references = PixPaymentLinkReferenceStore(
      await SharedPreferences.getInstance(),
    );
    addressReads = 0;
    keys = 0;
  });

  PixPaymentLinkFormController controller(
    _FakeLinks links, {
    Either<String, String> address = const Right('lq1qqwallet'),
  }) {
    return PixPaymentLinkFormController(
      repository: links,
      references: references,
      receiveAddress: () async {
        addressReads++;
        return address;
      },
      newIdempotencyKey: () => 'key-${++keys}',
    );
  }

  test(
    'creates the link to a wallet address and keeps its reference',
    () async {
      final links = _FakeLinks([Right(_link)]);

      final created = await controller(links).create(
        reference: 'Aula de março',
        singleUse: true,
        asset: Asset.lbtc,
        amountInCents: 4590,
      );

      expect(created?.reference, 'Aula de março');
      expect(links.creates.single, (
        amountInCents: 4590,
        asset: Asset.lbtc,
        address: 'lq1qqwallet',
        singleUse: true,
        key: 'key-1',
      ));
      expect(references.load(), {'link-1': 'Aula de março'});
    },
  );

  test('an open amount asks for a variable link', () async {
    final links = _FakeLinks([Right(_link)]);

    await controller(
      links,
    ).create(reference: 'Doação', singleUse: false, asset: Asset.depix);

    expect(links.creates.single.amountInCents, isNull);
  });

  test('a retry of the same charge repeats the address and the key', () async {
    final links = _FakeLinks([_refused, Right(_link)]);
    final form = controller(links);

    final first = await form.create(
      reference: 'Aula',
      singleUse: true,
      asset: Asset.depix,
      amountInCents: 4590,
    );
    expect(first, isNull);
    expect(form.state.failure?.code, PixHubErrorCode.serviceUnavailable);

    await form.create(
      reference: 'Aula',
      singleUse: true,
      asset: Asset.depix,
      amountInCents: 4590,
    );

    expect(links.creates.map((c) => c.key), ['key-1', 'key-1']);
    expect(addressReads, 1);
  });

  test('another charge after a failure gets a new key', () async {
    final links = _FakeLinks([_refused, Right(_link)]);
    final form = controller(links);

    await form.create(
      reference: 'Aula',
      singleUse: true,
      asset: Asset.depix,
      amountInCents: 4590,
    );
    await form.create(
      reference: 'Aula',
      singleUse: true,
      asset: Asset.depix,
      amountInCents: 5000,
    );

    // The API refuses one key with other inputs.
    expect(links.creates.map((c) => c.key), ['key-1', 'key-2']);
  });

  test('without a wallet address no request leaves', () async {
    final links = _FakeLinks([]);
    final form = controller(links, address: const Left('wallet locked'));

    final created = await form.create(
      reference: 'Aula',
      singleUse: true,
      asset: Asset.depix,
      amountInCents: 4590,
    );

    expect(created, isNull);
    expect(form.state.failure?.code, PixHubErrorCode.walletUnavailable);
    expect(links.creates, isEmpty);
  });
}
