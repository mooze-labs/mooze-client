import 'dart:math';

import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_demo_dataset.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_demo_store.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_overview.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_request.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_recipient.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_hub_repository.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link_amount.dart';

/// Answers every Pix hub screen from fictional data.
///
/// Mooze has no service for looking up recipients or registering keys, so
/// this repository simulates those screens. Nothing here reaches the network
/// and no money moves. The send flow uses the real withdrawal API instead.
///
/// The payment-link bounds come from [PaymentLinkAmount]. Mooze has no
/// payment-link API yet, so the hub keeps these bounds locally.
class DemoPixHubRepository implements PixHubRepository {
  /// Delay applied to every call, so the screens exercise their loading state.
  static const Duration _latency = Duration(milliseconds: 450);

  final PixDemoStore _store;
  final Random _random;

  DemoPixHubRepository(this._store, {Random? random})
    : _random = random ?? Random();

  @override
  TaskEither<PixHubFailure, PixHubOverview> loadOverview() {
    return _delayed(
      () => PixHubOverview(
        keys: _store.keys,
        recentRecipients: _store.recipients.take(6).toList(),
        recentTransactions: _store.transactions.take(4).toList(),
        pendingLinks: _store.paymentLinks
            .where((link) => link.status == PixPaymentLinkStatus.pending)
            .take(3)
            .toList(),
      ),
    );
  }

  @override
  TaskEither<PixHubFailure, List<PixKey>> listKeys() =>
      _delayed(() => _store.keys);

  @override
  TaskEither<PixHubFailure, List<PixRecipient>> listRecentRecipients() =>
      _delayed(() => _store.recipients);

  @override
  TaskEither<PixHubFailure, List<PixTransaction>> listTransactions() =>
      _delayed(() => _store.transactions);

  @override
  TaskEither<PixHubFailure, PixPaymentRequest> createPaymentRequest({
    required PixKey key,
    int? amountInCents,
    String? description,
  }) {
    if (amountInCents != null &&
        (amountInCents < PixPaymentRequest.minAmountInCents ||
            amountInCents > PixPaymentRequest.maxAmountInCents)) {
      return TaskEither.left(
        const PixHubFailure(PixHubErrorCode.amountOutOfBounds),
      );
    }

    return _delayed(() {
      final now = DateTime.now();
      final id = _reference();
      return PixPaymentRequest(
        id: id,
        key: key,
        amountInCents: amountInCents,
        description: description,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
        brCode: PixDemoDataset.brCodeFor(
          pixKey: key.value,
          amountInCents: amountInCents,
          transactionId: id,
          description: description,
        ),
      );
    });
  }

  @override
  TaskEither<PixHubFailure, List<PixPaymentLink>> listPaymentLinks() =>
      _delayed(() => _store.paymentLinks);

  @override
  TaskEither<PixHubFailure, PixPaymentLink> createPaymentLink({
    required String reference,
    required bool singleUse,
    int? amountInCents,
  }) {
    if (amountInCents != null) {
      final policy = FixedPaymentLinkAmount(amountInCents);
      if (!policy.isWithinBounds) {
        return TaskEither.left(
          const PixHubFailure(PixHubErrorCode.amountOutOfBounds),
        );
      }
    }

    return _delayed(() {
      final link = PixPaymentLink(
        id: 'demo-link-${DateTime.now().microsecondsSinceEpoch}',
        url: '${PixDemoDataset.demoLinkHost}/${_slug()}',
        reference: reference,
        amountInCents: amountInCents,
        status: PixPaymentLinkStatus.pending,
        createdAt: DateTime.now(),
        singleUse: singleUse,
      );
      _store.addPaymentLink(link);
      return link;
    });
  }

  @override
  TaskEither<PixHubFailure, Unit> deletePaymentLink(String id) {
    return _delayed(() {
      _store.removePaymentLink(id);
      return unit;
    });
  }

  TaskEither<PixHubFailure, T> _delayed<T>(
    T Function() compute, {
    Duration? duration,
  }) {
    return TaskEither.tryCatch(
      () async {
        await Future<void>.delayed(duration ?? _latency);
        return compute();
      },
      (error, _) =>
          PixHubFailure(PixHubErrorCode.unknown, rawMessage: error.toString()),
    );
  }

  String _reference() {
    const alphabet = '0123456789ABCDEF';
    final suffix = List.generate(
      6,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
    return '${PixDemoDataset.referencePrefix}-$suffix';
  }

  String _slug() {
    const alphabet = 'abcdef0123456789';
    return List.generate(
      6,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }
}
