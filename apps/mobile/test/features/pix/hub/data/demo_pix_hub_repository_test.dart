import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_demo_dataset.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_demo_store.dart';
import 'package:mooze_mobile/features/pix/hub/data/repositories/demo_pix_hub_repository.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_recipient.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link_amount.dart';

import '../check_digit_core_sync_helpers.dart';
import '../../../../shared/fake_core_sync_helpers.dart';

void main() {
  useCoreSyncHelpers(const CheckDigitCoreSyncHelpers());

  late PixDemoStore store;
  late DemoPixHubRepository repository;

  setUp(() {
    store = PixDemoStore();
    repository = DemoPixHubRepository(store);
  });

  group('loadOverview', () {
    test('fills every section from the demonstration dataset', () async {
      final result = await repository.loadOverview().run();
      final overview = result.getOrElse((_) => throw StateError('failed'));

      expect(overview.keys, isNotEmpty);
      expect(overview.recentRecipients, isNotEmpty);
      expect(overview.recentTransactions, isNotEmpty);
      expect(overview.pendingLinks, isNotEmpty);
    });

    test('answers empty while the empty preview is on', () async {
      store.emptyMode = true;

      final result = await repository.loadOverview().run();
      final overview = result.getOrElse((_) => throw StateError('failed'));

      expect(overview.keys, isEmpty);
      expect(overview.recentRecipients, isEmpty);
      expect(overview.recentTransactions, isEmpty);
      expect(overview.pendingLinks, isEmpty);
    });
  });

  group('createPaymentRequest', () {
    test('builds a charge whose code carries the amount', () async {
      final key = store.keys.first;
      final result = await repository
          .createPaymentRequest(key: key, amountInCents: 12345)
          .run();
      final request = result.getOrElse((_) => throw StateError('failed'));

      expect(request.amountInCents, 12345);
      expect(request.brCode, contains('BR.GOV.BCB.PIX'));
      expect(request.expiresAt.isAfter(request.createdAt), isTrue);
    });

    test('rejects an amount below the minimum', () async {
      final result = await repository
          .createPaymentRequest(key: store.keys.first, amountInCents: 1)
          .run();

      expect(
        result.getLeft().toNullable()?.code,
        PixHubErrorCode.amountOutOfBounds,
      );
    });
  });

  group('createPaymentLink', () {
    test('stores a link with a fictional address', () async {
      final result = await repository
          .createPaymentLink(
            reference: 'Aula de demonstracao',
            singleUse: true,
            amountInCents: 20000,
          )
          .run();
      final link = result.getOrElse((_) => throw StateError('failed'));

      expect(link.url, startsWith(PixDemoDataset.demoLinkHost));
      expect(store.paymentLinks.first.id, link.id);
    });

    test('rejects an amount outside the bounds of the real API', () async {
      final result = await repository
          .createPaymentLink(
            reference: 'Fora do limite',
            singleUse: true,
            amountInCents: PaymentLinkAmount.maxAmountInCents + 1,
          )
          .run();

      expect(
        result.getLeft().toNullable()?.code,
        PixHubErrorCode.amountOutOfBounds,
      );
    });
  });

  group('deletePaymentLink', () {
    test('removes the link from the list', () async {
      final target = store.paymentLinks.first;

      final result = await repository.deletePaymentLink(target.id).run();

      expect(result.isRight(), isTrue);
      expect(store.paymentLinks.where((link) => link.id == target.id), isEmpty);
    });

    test('leaves the list untouched for an unknown id', () async {
      final before = store.paymentLinks.length;

      final result = await repository.deletePaymentLink('nope').run();

      expect(result.isRight(), isTrue);
      expect(store.paymentLinks.length, before);
    });
  });

  group('PixRecipient', () {
    test('builds the initials from the first and the last name', () {
      const recipient = PixRecipient(
        id: 'x',
        name: 'Ana Maria Demonstracao',
        maskedDocument: '***',
        institution: 'Banco Exemplo',
        keyType: PixKeyType.email,
        keyValue: 'ana@exemplo.invalid',
      );

      expect(recipient.initials, 'AD');
    });
  });
}
