import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_demo_dataset.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_recipient.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';

/// In-memory state of the demonstration data.
///
/// The store keeps what the user creates during the session — payments, charges
/// and links — so the flows behave like a real product while the app runs. The
/// data never reaches disk or the network.
class PixDemoStore {
  /// Balance the simulated payments draw from, in BRL cents.
  ///
  /// A payment above this value is declined, so the failure path of the send
  /// flow stays reachable without a real service.
  static const int simulatedBalanceInCents = 250000;

  bool _emptyMode = false;

  final List<PixKey> _keys = PixDemoDataset.keys();
  final List<PixRecipient> _recipients = PixDemoDataset.recipients();
  final List<PixTransaction> _transactions = PixDemoDataset.transactions();
  final List<PixPaymentLink> _links = PixDemoDataset.paymentLinks();

  /// True when every list answers empty, used to review the empty states.
  bool get isEmptyMode => _emptyMode;

  set emptyMode(bool value) => _emptyMode = value;

  List<PixKey> get keys => _emptyMode ? const [] : List.unmodifiable(_keys);

  List<PixRecipient> get recipients =>
      _emptyMode ? const [] : List.unmodifiable(_recipients);

  List<PixTransaction> get transactions =>
      _emptyMode ? const [] : List.unmodifiable(_transactions);

  List<PixPaymentLink> get paymentLinks =>
      _emptyMode ? const [] : List.unmodifiable(_links);

  /// Records a movement at the top of the history.
  void addTransaction(PixTransaction transaction) {
    _transactions.insert(0, transaction);
  }

  /// Records a link at the top of the list.
  void addPaymentLink(PixPaymentLink link) {
    _links.insert(0, link);
  }

  /// Removes the link [id]. Answers false when the list has no such link.
  bool removePaymentLink(String id) {
    final before = _links.length;
    _links.removeWhere((link) => link.id == id);
    return _links.length != before;
  }

  /// Moves [recipient] to the top of the recent list, without duplicates.
  void touchRecipient(PixRecipient recipient) {
    _recipients.removeWhere((item) => item.id == recipient.id);
    _recipients.insert(
      0,
      PixRecipient(
        id: recipient.id,
        name: recipient.name,
        maskedDocument: recipient.maskedDocument,
        institution: recipient.institution,
        keyType: recipient.keyType,
        keyValue: recipient.keyValue,
        lastPaidAt: DateTime.now(),
      ),
    );
  }

  /// Finds a recipient by key, or null when the demonstration data has none.
  PixRecipient? findRecipientByKey(String key) {
    final needle = _normalize(key);
    for (final recipient in _recipients) {
      if (_normalize(recipient.keyValue) == needle) return recipient;
    }
    return null;
  }

  static String _normalize(String key) =>
      key.trim().toLowerCase().replaceAll(RegExp(r'[\s().-]'), '');
}
