import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_recipient.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';

/// Everything the Pix hub home screen shows in one read.
class PixHubOverview {
  final List<PixKey> keys;
  final List<PixRecipient> recentRecipients;
  final List<PixTransaction> recentTransactions;
  final List<PixPaymentLink> pendingLinks;

  const PixHubOverview({
    required this.keys,
    required this.recentRecipients,
    required this.recentTransactions,
    required this.pendingLinks,
  });

  /// An overview with every section empty, used by the empty-state preview.
  static const PixHubOverview empty = PixHubOverview(
    keys: [],
    recentRecipients: [],
    recentTransactions: [],
    pendingLinks: [],
  );
}
