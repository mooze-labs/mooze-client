import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_payment_link_reference_store.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_payment_link_repository.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

PixPaymentLink _link(String id) => PixPaymentLink(
  id: id,
  url: 'https://pay.mooze.app/pay/tok_$id',
  reference: '',
  status: PixPaymentLinkStatus.pending,
  createdAt: DateTime.utc(2026, 11, 11),
  singleUse: true,
  amountInCents: 4590,
);

/// The API, which counts the reads of the list.
class _FakeLinks implements PixPaymentLinkRepository {
  var reads = 0;

  @override
  TaskEither<PixHubFailure, List<PixPaymentLink>> listLinks() {
    reads++;
    return TaskEither.right([_link('link-1'), _link('link-2')]);
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
  TaskEither<PixHubFailure, Unit> revokeLink(String id) =>
      throw UnimplementedError();
}

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  late SharedPreferences prefs;
  late _FakeLinks api;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await PixPaymentLinkReferenceStore(prefs).save('link-2', 'Aluguel');
    api = _FakeLinks();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pixPaymentLinkRepositoryProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    // The list lives while a screen shows it.
    container.listen(pixHubPaymentLinksProvider, (_, _) {});
    await container.read(pixHubPaymentLinksProvider.future);
  });

  List<PixPaymentLink> links() =>
      container.read(pixHubPaymentLinksProvider).requireValue;

  Future<void> rename(String id, String reference) => container
      .read(pixPaymentLinkReferencesProvider.notifier)
      .rename(id, reference);

  // A name only organizes the links of the owner, so a rename shows at
  // once, with no new read of the API.
  test('a rename shows on the list at once, with no new read', () async {
    await rename('link-1', 'Aula de março');

    expect(links().map((l) => l.reference), ['Aula de março', 'Aluguel']);
    expect(api.reads, 1);
  });

  test('the name stays on the device', () async {
    await rename('link-1', 'Aula de março');

    expect(PixPaymentLinkReferenceStore(prefs).load(), {
      'link-1': 'Aula de março',
      'link-2': 'Aluguel',
    });
    expect(container.read(pixPaymentLinkReferencesProvider), {
      'link-1': 'Aula de março',
      'link-2': 'Aluguel',
    });
  });

  test('an empty name takes the name away: the link shows the generic '
      'name', () async {
    await rename('link-2', '');

    expect(pixPaymentLinkTitle(t, links()[1]), t.pix_hub_link_no_reference);
  });

  // A link created after the names were read keeps the name that it was
  // created with.
  test('a new link keeps its name when the list reads again', () async {
    container.read(pixPaymentLinkReferencesProvider);
    await PixPaymentLinkReferenceStore(prefs).save('link-1', 'Bolo de pote');

    container.invalidate(pixHubPaymentLinksProvider);
    await container.read(pixHubPaymentLinksProvider.future);

    expect(links().first.reference, 'Bolo de pote');
  });

  // The create screen saves the name of a new link to the device. A later
  // rename of another link must not take it away.
  test('a rename keeps the name of a link created since', () async {
    container.read(pixPaymentLinkReferencesProvider);
    await PixPaymentLinkReferenceStore(prefs).save('link-1', 'Bolo de pote');
    container.invalidate(pixHubPaymentLinksProvider);
    await container.read(pixHubPaymentLinksProvider.future);

    await rename('link-2', 'Casa');

    expect(links().map((l) => l.reference), ['Bolo de pote', 'Casa']);
  });
}
