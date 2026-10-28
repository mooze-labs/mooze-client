import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_request.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/deposit/pix_deposit_gate_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/history/pix_hub_history_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/history/pix_transaction_detail_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/keys/pix_keys_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/links/pix_payment_link_create_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/links/pix_payment_link_detail_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/links/pix_payment_links_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/operations/pix_limits_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/operations/pix_other_transactions_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/operations/pix_pending_requests_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/receive/pix_payment_request_detail_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/receive/pix_payment_request_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/receive/pix_receive_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_amount_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_copy_paste_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_key_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_method_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_result_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_review_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_scan_screen.dart';

/// Routes of the Pix hub.
///
/// The hub home itself lives at `/pix`, inside the main navigation shell, so it
/// is registered by the wallet routes together with the other tabs.
final pixHubRoutes = [
  GoRoute(
    path: '/pix/send',
    builder: (context, state) => const PixSendMethodScreen(),
  ),
  GoRoute(
    path: '/pix/send/key',
    builder: (context, state) => const PixSendKeyScreen(),
  ),
  GoRoute(
    path: '/pix/send/scan',
    builder: (context, state) => const PixSendScanScreen(),
  ),
  GoRoute(
    path: '/pix/send/code',
    builder: (context, state) => const PixSendCopyPasteScreen(),
  ),
  GoRoute(
    path: '/pix/send/amount',
    builder: (context, state) => const PixSendAmountScreen(),
  ),
  GoRoute(
    path: '/pix/send/review',
    builder: (context, state) => const PixSendReviewScreen(),
  ),
  GoRoute(
    path: '/pix/send/result',
    builder: (context, state) => const PixSendResultScreen(),
  ),
  GoRoute(
    path: '/pix/receive',
    builder: (context, state) => const PixReceiveScreen(),
  ),
  GoRoute(
    path: '/pix/receive/request',
    builder: (context, state) => const PixPaymentRequestScreen(),
  ),
  GoRoute(
    path: '/pix/receive/request/detail',
    builder: (context, state) => PixPaymentRequestDetailScreen(
      request: state.extra as PixPaymentRequest,
    ),
  ),
  GoRoute(
    path: '/pix/keys',
    builder: (context, state) => const PixKeysScreen(),
  ),
  GoRoute(
    path: '/pix/limits',
    builder: (context, state) => const PixLimitsScreen(),
  ),
  GoRoute(
    path: '/pix/pending',
    builder: (context, state) => const PixPendingRequestsScreen(),
  ),
  GoRoute(
    path: '/pix/transactions',
    builder: (context, state) => const PixOtherTransactionsScreen(),
  ),
  GoRoute(
    path: '/pix/deposit/cpf',
    builder: (context, state) => const PixDepositGateScreen(),
  ),
  GoRoute(
    path: '/pix/deposit/notice',
    builder: (context, state) => const PixDepositNoticeScreen(),
  ),
  GoRoute(
    path: '/pix/links',
    builder: (context, state) => const PixPaymentLinksScreen(),
  ),
  GoRoute(
    path: '/pix/links/new',
    builder: (context, state) => const PixPaymentLinkCreateScreen(),
  ),
  GoRoute(
    path: '/pix/links/detail',
    builder: (context, state) =>
        PixPaymentLinkDetailScreen(link: state.extra as PixPaymentLink),
  ),
  GoRoute(
    path: '/pix/history',
    builder: (context, state) => const PixHubHistoryScreen(),
  ),
  GoRoute(
    path: '/pix/history/detail',
    builder: (context, state) =>
        PixTransactionDetailScreen(transaction: state.extra as PixTransaction),
  ),
];
