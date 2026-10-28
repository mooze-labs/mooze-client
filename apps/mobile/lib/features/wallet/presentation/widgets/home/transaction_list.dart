import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/v2_legacy_transactions_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/pending_swap_item.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/diagnostics/boot_tracer.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/utils/transaction_formatters.dart';
import 'package:intl/intl.dart';

/// Number of persisted rows on the home preview. The full list lives on
/// `/transactions-history`.
const int _homePreviewLimit = 5;

/// Mask that replaces a hidden transaction amount.
const String _amountMask = '•••••••';

class TransactionList extends ConsumerStatefulWidget {
  const TransactionList({super.key});

  @override
  ConsumerState<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends ConsumerState<TransactionList> {
  // Captured at first paint so we don't spam the trace with a mark per
  // rebuild. Use cases: distinguish "first time home renders txs" from
  // ongoing stream-driven rebuilds.
  bool _markedFirstPaint = false;
  int? _markedLength;

  void _onPaint(int len, {required String source}) {
    if (!_markedFirstPaint) {
      _markedFirstPaint = true;
      BootTracer.mark('home.tx_list.first_paint', {
        'len': len,
        'source': source,
      });
    } else if (_markedLength != len) {
      BootTracer.mark('home.tx_list.length_change', {
        'len': len,
        'prev': _markedLength,
        'source': source,
      });
    }
    _markedLength = len;
  }

  /// IDs of the preview rows seen so far. Null until the first data.
  ///
  /// The state starts again when the home screen mounts again, so a tab
  /// return shows the rows without an insert animation.
  Set<String>? _seenIds;

  /// IDs of rows that appeared after the first data. Each of these rows
  /// animates in once.
  Set<String> _insertedIds = const {};

  /// Finds rows that are new since the last data and announces new
  /// received transactions to screen readers.
  void _trackInserts(List<Transaction> visible) {
    final ids = {for (final tx in visible) tx.id};
    final seen = _seenIds;
    if (seen == null) {
      _seenIds = ids;
      return;
    }
    final newIds = ids.difference(seen);
    seen.addAll(ids);
    if (newIds.isEmpty) return;
    // More than one row and all rows new: this is a reload, for example a
    // wallet switch or a first sync. Do not animate and do not announce.
    if (ids.length > 1 && newIds.length == ids.length) return;

    _insertedIds = {..._insertedIds, ...newIds};
    final received = [
      for (final tx in visible)
        if (newIds.contains(tx.id) && tx.type == TransactionType.receive) tx,
    ];
    if (received.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(received));
  }

  /// Announces [received] transactions. A hidden balance hides the amount
  /// in the announcement too.
  void _announce(List<Transaction> received) {
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    // `isVisibleProvider` is true when the balance is hidden.
    final isHidden = ref.read(isVisibleProvider);
    final message = [
      for (final tx in received)
        isHidden
            ? t.wallet_tx_received(tx.asset.ticker)
            : '${t.wallet_tx_received(tx.asset.ticker)}, '
                  '${TransactionValueFormatter.formatTransactionValue(transaction: tx)}',
    ].join('. ');
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(v2LegacyTransactionsProvider);
    final isVisible = ref.watch(isVisibleProvider);
    final pendingSwaps = ref.watch(pendingSwapsProvider);
    // Side-effect provider — drops optimistic rows once the persisted
    // store catches up. Watching here keeps the listener alive for
    // the lifetime of the home screen.
    ref.watch(pendingSwapsReconciliationProvider);

    return transactionsAsync.when(
      loading: () {
        if (pendingSwaps.isEmpty) {
          return const LoadingTransactionList(glass: true);
        }
        _onPaint(pendingSwaps.length, source: 'loading+pending');
        return _TransactionListBody(
          transactions: const [],
          pendingSwaps: pendingSwaps,
          isVisible: isVisible,
          insertedIds: _insertedIds,
        );
      },
      error: (err, _) {
        if (pendingSwaps.isEmpty) {
          return const ErrorTransactionList();
        }
        _onPaint(pendingSwaps.length, source: 'error+pending');
        return _TransactionListBody(
          transactions: const [],
          pendingSwaps: pendingSwaps,
          isVisible: isVisible,
          insertedIds: _insertedIds,
        );
      },
      data: (transactions) {
        _onPaint(transactions.length + pendingSwaps.length, source: 'data');
        _trackInserts(
          _hideInFlightLegs(
            transactions,
            pendingSwaps,
          ).take(_homePreviewLimit).toList(),
        );
        return _TransactionListBody(
          transactions: transactions,
          pendingSwaps: pendingSwaps,
          isVisible: isVisible,
          insertedIds: _insertedIds,
        );
      },
    );
  }
}

class _TransactionListBody extends StatelessWidget {
  final List<Transaction> transactions;
  final List<PendingSwap> pendingSwaps;
  final bool isVisible;
  final Set<String> insertedIds;

  const _TransactionListBody({
    required this.transactions,
    required this.pendingSwaps,
    required this.isVisible,
    required this.insertedIds,
  });

  @override
  Widget build(BuildContext context) {
    // While an optimistic peg-in/out row is alive, hide the raw send
    // leg that belongs to it from the persisted list — otherwise the
    // user briefly sees two rows for the same operation (the
    // animated optimistic card + a plain "BTC sent" / "LBTC sent"
    // entry) for the ~minutes-to-hours gap between the lockup tx
    // appearing and the unifier pairing both legs.
    final filtered = _hideInFlightLegs(transactions, pendingSwaps);

    if (pendingSwaps.isEmpty && filtered.isEmpty) {
      return const EmptyTransactionList(glass: true);
    }

    return SuccessfulTransactionList(
      transactions: filtered,
      isVisible: isVisible,
      glass: true,
      // Home preview: cap at 5 most-recent rows. The full list
      // lives on `/transactions-history`. Without this cap a
      // 218-tx wallet builds ~545ms of off-screen rows on every
      // first paint of /home — a measured UI-thread block.
      limit: _homePreviewLimit,
      animateInIds: insertedIds,
      // One panel: the preview is short, so each row shows its day.
      groupByDate: false,
      leadingRows: [
        for (final swap in pendingSwaps) PendingSwapItem(swap: swap),
      ],
    );
  }
}

bool _isRefundedBtcPeg(Transaction tx) {
  final from = tx.fromAsset;
  final to = tx.toAsset;
  if (from == null || to == null) return false;
  if (from != to) return false;
  if (from != Asset.btc) return false;
  if (tx.blockchain != Blockchain.bitcoin) return false;
  if (tx.sendBlockchain != null && tx.sendBlockchain != Blockchain.bitcoin) {
    return false;
  }
  if (tx.receiveBlockchain != null &&
      tx.receiveBlockchain != Blockchain.bitcoin) {
    return false;
  }
  return true;
}

List<Transaction> _hideInFlightLegs(
  List<Transaction> persisted,
  List<PendingSwap> pendingSwaps,
) {
  if (pendingSwaps.isEmpty || persisted.isEmpty) return persisted;

  final lockupTxIds = <String>{};
  for (final p in pendingSwaps) {
    final id = p.breezTxId;
    if (id != null) lockupTxIds.add(id);
  }
  if (lockupTxIds.isEmpty) return persisted;

  return [
    for (final t in persisted)
      if (!lockupTxIds.contains(t.id) &&
          !(t.sendTxId != null && lockupTxIds.contains(t.sendTxId)) &&
          !(t.receiveTxId != null && lockupTxIds.contains(t.receiveTxId)))
        t,
  ];
}

class SuccessfulTransactionList extends ConsumerWidget {
  final List<Transaction> transactions;
  final bool isVisible;

  /// Maximum number of rows to render. When non-null, only the first
  /// `limit` transactions of [transactions] are built; the rest are
  /// ignored. Caller is responsible for ordering [transactions] by
  /// recency so the surfaced subset is the most useful slice.
  ///
  /// Rationale: the home screen renders this list inside a
  /// `SingleChildScrollView` (no virtualization). Without a cap, a
  /// wallet with 218 historical txs paid ~545ms of UI-thread layout
  /// on first paint just to materialize rows the user couldn't see
  /// without scrolling. Passing `limit: 5` on the home keeps the
  /// "preview" cheap and the full list lives on
  /// `/transactions-history`, which has its own pull-to-refresh and
  /// filter UI for the long-tail use case.
  final int? limit;

  /// IDs of rows that animate in when they first build. The home preview
  /// passes the rows that arrived after its first data. Other screens pass
  /// nothing, so their rows do not animate.
  final Set<String> animateInIds;

  /// Groups the rows by day, one panel per day under a date header. The
  /// home preview passes false: it shows one panel and puts the day next
  /// to the time of each row.
  final bool groupByDate;

  /// Rows at the top of the first panel, for example swaps in progress.
  final List<Widget> leadingRows;

  /// Draws the panels as Liquid Glass. The home preview passes true. Other
  /// screens keep the plain panel.
  final bool glass;

  const SuccessfulTransactionList({
    super.key,
    required this.transactions,
    required this.isVisible,
    this.limit,
    this.animateInIds = const {},
    this.groupByDate = true,
    this.leadingRows = const [],
    this.glass = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lim = limit;
    final source = (lim != null && transactions.length > lim)
        ? transactions.sublist(0, lim)
        : transactions;

    if (source.isEmpty && leadingRows.isEmpty) {
      return EmptyTransactionList(glass: glass);
    }

    final t = AppLocalizations.of(context);
    final dates = _TransactionDates(context, t);
    final leading = [
      for (var i = 0; i < leadingRows.length; i++) ...[
        if (i > 0) const PanelDivider(indent: HomeTransactionItem.textInset),
        leadingRows[i],
      ],
    ];

    if (!groupByDate) {
      return _ListPanel(
        glass: glass,
        child: Column(
          children: [
            ...leading,
            for (var i = 0; i < source.length; i++)
              _row(
                context,
                t,
                source[i],
                time: dates.dayAndTime(source[i].createdAt),
                divider: i > 0 || leading.isNotEmpty,
              ),
          ],
        ),
      );
    }

    final groups = _groupByDay(source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leading.isNotEmpty)
          _ListPanel(
            glass: glass,
            child: Column(children: leading),
          ),
        for (var g = 0; g < groups.length; g++) ...[
          _DateHeader(
            label: dates.day(groups[g].first.createdAt),
            isFirst: g == 0 && leading.isEmpty,
          ),
          _ListPanel(
            glass: glass,
            child: Column(
              children: [
                for (var i = 0; i < groups[g].length; i++)
                  _row(
                    context,
                    t,
                    groups[g][i],
                    time: dates.time(groups[g][i].createdAt),
                    divider: i > 0,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Splits [source] into runs of transactions from the same day. The order
  /// of [source] stays the same.
  static List<List<Transaction>> _groupByDay(List<Transaction> source) {
    final groups = <List<Transaction>>[];
    for (final tx in source) {
      final day = DateUtils.dateOnly(tx.createdAt);
      if (groups.isNotEmpty &&
          DateUtils.dateOnly(groups.last.first.createdAt) == day) {
        groups.last.add(tx);
      } else {
        groups.add([tx]);
      }
    }
    return groups;
  }

  Widget _row(
    BuildContext context,
    AppLocalizations t,
    Transaction transaction, {
    required String time,
    required bool divider,
  }) {
    return _RowInsert(
      key: ValueKey(transaction.id),
      animate: animateInIds.contains(transaction.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (divider)
            const PanelDivider(indent: HomeTransactionItem.textInset),
          MergeSemantics(
            child: InkWell(
              onTap: () {
                context.push('/transactions/details', extra: transaction);
              },
              child: HomeTransactionItem(
                icon: transaction.asset.iconPath,
                title: _getTransactionTitle(t, transaction),
                subtitle: _getTransactionSubtitle(t, transaction),
                value: TransactionValueFormatter.formatTransactionValue(
                  transaction: transaction,
                ),
                time: time,
                isVisible: isVisible,
                transaction: transaction,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTransactionTitle(AppLocalizations t, Transaction transaction) {
    if (transaction.fromAsset != null &&
        transaction.toAsset != null &&
        transaction.sentAmount != null &&
        transaction.receivedAmount != null) {
      // Same-asset swap = a refunded peg attempt: the conversion
      // never completed; the funds came back (minus the swap-service
      // refund fee). Render it as a refund instead of as a regular
      // swap so the user can tell at a glance.
      if (_isRefundedBtcPeg(transaction)) {
        return 'Refunded ${transaction.asset.ticker} swap';
      }
      return t.wallet_tx_swap_pair(
        transaction.fromAsset!.ticker,
        transaction.toAsset!.ticker,
      );
    }

    if (transaction.type == TransactionType.send &&
        transaction.asset == Asset.usdt) {
      return t.wallet_tx_sent(transaction.asset.ticker);
    }

    if (transaction.type == TransactionType.receive &&
        transaction.asset == Asset.lbtc) {
      return t.wallet_tx_received(transaction.asset.ticker);
    }

    switch (transaction.type) {
      case TransactionType.send:
        return t.wallet_tx_sent(transaction.asset.ticker);
      case TransactionType.receive:
        return t.wallet_tx_received(transaction.asset.ticker);
      case TransactionType.swap:
        return t.wallet_tx_swap_pair(
          transaction.fromAsset!.ticker,
          transaction.toAsset!.ticker,
        );
      case TransactionType.submarine:
        return t.wallet_tx_swap_pair(
          transaction.fromAsset!.ticker,
          transaction.toAsset!.ticker,
        );
      case TransactionType.redeposit:
        return t.wallet_tx_redeposit(transaction.asset.ticker);
      case TransactionType.unknown:
        return t.wallet_tx_unknown;
    }
  }

  String _getTransactionSubtitle(AppLocalizations t, Transaction transaction) {
    return _getStatusText(t, transaction.status);
  }

  String _getStatusText(AppLocalizations t, TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return t.tx_status_pending;
      case TransactionStatus.confirmed:
        return t.tx_status_confirmed;
      case TransactionStatus.failed:
        return t.tx_status_failed;
      case TransactionStatus.refundable:
        return t.tx_status_refundable;
    }
  }
}

/// Day and time labels of the transaction rows.
///
/// Today and yesterday read as words. Other days show the day and the
/// short month, and the year when it is not the current year.
class _TransactionDates {
  _TransactionDates(BuildContext context, this.t)
    : _locale = Localizations.localeOf(context).toString(),
      _today = DateUtils.dateOnly(DateTime.now());

  final AppLocalizations t;
  final String _locale;
  final DateTime _today;

  String day(DateTime date) {
    final day = DateUtils.dateOnly(date);
    if (day == _today) return t.wallet_tx_date_today;
    final yesterday = DateTime(_today.year, _today.month, _today.day - 1);
    if (day == yesterday) return t.wallet_tx_date_yesterday;
    final pattern = day.year == _today.year ? 'd MMM' : 'd MMM y';
    return DateFormat(pattern, _locale).format(day);
  }

  String time(DateTime date) => DateFormat('HH:mm', _locale).format(date);

  String dayAndTime(DateTime date) => '${day(date)}, ${time(date)}';
}

/// Date label above one day of transactions.
class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label, required this.isFirst});

  final String label;

  /// The first header needs no space above it.
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, isFirst ? 0 : 20, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Animates a row in once: its height grows from 0 and it fades in.
///
/// The animation runs over [Motion.durationEmphasis] with
/// [Motion.curveEnter]. A row without [animate], or with reduced motion,
/// shows at once.
class _RowInsert extends StatefulWidget {
  const _RowInsert({super.key, required this.animate, required this.child});

  final bool animate;
  final Widget child;

  @override
  State<_RowInsert> createState() => _RowInsertState();
}

class _RowInsertState extends State<_RowInsert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationEmphasis,
    value: widget.animate ? 0 : 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.curveEnter,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !widget.animate) return;
    _started = true;
    if (Motion.isReduced(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward().whenComplete(() {
      // Drop the transition widgets when the insert ends.
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isCompleted) return widget.child;
    return SizeTransition(
      sizeFactor: _curve,
      axisAlignment: -1,
      child: FadeTransition(opacity: _curve, child: widget.child),
    );
  }
}

class LoadingTransactionList extends StatelessWidget {
  const LoadingTransactionList({super.key, this.glass = false});

  /// Draws the panel as Liquid Glass, as the list that replaces it.
  final bool glass;

  @override
  Widget build(BuildContext context) {
    return _ListPanel(
      glass: glass,
      child: SkeletonShimmer(
        child: Column(
          children: List.generate(
            3,
            (index) => const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: HomeTransactionItem.horizontalPadding,
                vertical: 14,
              ),
              child: Row(
                children: [
                  SkeletonBox.circle(size: HomeTransactionItem.leadingSize),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 120, height: 16),
                        SizedBox(height: 6),
                        SkeletonBox(width: 80, height: 12),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 72, height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorTransactionList extends StatelessWidget {
  const ErrorTransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final muted = context.colors.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: muted, size: 48),
          const SizedBox(height: 12),
          Text(
            t.wallet_tx_load_error_title,
            style: context.textTheme.bodyLarge?.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            t.wallet_tx_load_error_retry,
            style: context.textTheme.bodyMedium?.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class EmptyTransactionList extends StatelessWidget {
  const EmptyTransactionList({super.key, this.glass = false});

  /// Draws the panel as Liquid Glass, as the list that replaces it.
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _ListPanel(
      glass: glass,
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: context.colors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              t.wallet_tx_empty_title,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t.wallet_tx_empty_body,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTransactionItem extends StatelessWidget {
  /// Size of the leading icon area.
  static const double leadingSize = 40;

  /// Space between the panel edge and the row content.
  static const double horizontalPadding = 16;

  /// Distance from the panel edge to the row text. Dividers start here.
  static const double textInset = horizontalPadding + leadingSize + 12;

  final String icon;
  final String title;

  /// The status, for example "Confirmed".
  final String subtitle;

  final String value;

  /// The time, or the day and the time. It follows the status.
  final String time;

  /// True when the balance is hidden.
  final bool isVisible;
  final Transaction? transaction;

  const HomeTransactionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.time,
    required this.isVisible,
    this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isSwapByType = transaction?.type == TransactionType.swap;
    final isSubmarineSwap = transaction?.type == TransactionType.submarine;
    final isSwapByData =
        transaction?.fromAsset != null &&
        transaction?.toAsset != null &&
        transaction?.sentAmount != null &&
        transaction?.receivedAmount != null;

    final isSwap = isSwapByType || isSwapByData;
    final hasSwapDetails =
        (isSwap || isSubmarineSwap) &&
        transaction?.fromAsset != null &&
        transaction?.toAsset != null;

    final isSettledOrPending =
        transaction?.status != TransactionStatus.refundable &&
        transaction?.status != TransactionStatus.failed;

    final shouldHideValue = isSwap && !isSettledOrPending;

    // A swap shows what came in and what went out on the right.
    final showSwapAmounts =
        hasSwapDetails &&
        isSettledOrPending &&
        transaction?.sentAmount != null &&
        transaction?.receivedAmount != null;

    final isLightning = transaction?.blockchain == Blockchain.lightning;
    final meta = time.isEmpty ? subtitle : '$subtitle · $time';

    return Container(
      color: Colors.transparent,
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            ExcludeSemantics(
              child: hasSwapDetails
                  ? _buildSwapIcon(context)
                  : _buildAssetIcon(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          meta,
                          style: _secondaryStyle(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLightning) ...[
                        const SizedBox(width: 6),
                        const _LightningTag(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // The amounts take at most 45% of the row. A wider amount scales
            // down, so it never wraps or overflows.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.45,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: showSwapAmounts
                    ? _buildSwapAmounts(context)
                    : _buildAmount(
                        context,
                        showValue: !(shouldHideValue || isSwap),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle? _secondaryStyle(BuildContext context) => context
      .textTheme
      .bodySmall
      ?.copyWith(color: context.colors.textSecondary);

  static TextStyle? _amountStyle(BuildContext context) =>
      context.textTheme.bodyLarge?.copyWith(
        color: context.colors.textPrimary,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// The signed amount, or a mask when the balance is hidden.
  ///
  /// The sign and the direction badge show the direction, so the amount
  /// uses the primary text color.
  Widget _buildAmount(BuildContext context, {required bool showValue}) {
    final style = _amountStyle(context);
    if (!showValue) return Text('', style: style);
    return _masked(context, Text(value, style: style));
  }

  /// The received amount, and the sent amount below it in a smaller size.
  Widget _buildSwapAmounts(BuildContext context) {
    final received = _formatSwapAmount(
      transaction!.toAsset!,
      transaction!.receivedAmount!,
    );
    final sent = _formatSwapAmount(
      transaction!.fromAsset!,
      transaction!.sentAmount!,
    );
    return _masked(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('+$received', style: _amountStyle(context)),
          const SizedBox(height: 2),
          Text(
            '-$sent',
            style: _secondaryStyle(
              context,
            )?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }

  /// Cross-fades [child] and the mask over [Motion.durationFast] when the
  /// balance visibility changes.
  Widget _masked(BuildContext context, Widget child) {
    // `isVisible` is true when the balance is hidden.
    final Widget shown = isVisible
        ? Semantics(
            key: const ValueKey('mask'),
            label: AppLocalizations.of(context).wallet_amount_hidden,
            excludeSemantics: true,
            child: Text(_amountMask, style: _amountStyle(context)),
          )
        : KeyedSubtree(key: const ValueKey('value'), child: child);

    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.durationFast),
      switchInCurve: Motion.curveMove,
      switchOutCurve: Motion.curveMove,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerEnd,
        children: [...previous, if (current != null) current],
      ),
      child: shown,
    );
  }

  /// Asset icon with a badge that shows the direction of the transaction.
  Widget _buildAssetIcon(BuildContext context) {
    final glyph = switch (transaction?.type) {
      TransactionType.send => Icons.north_east,
      TransactionType.receive => Icons.south_west,
      TransactionType.redeposit => Icons.replay,
      _ => null,
    };
    return SizedBox.square(
      dimension: leadingSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SvgPicture.asset(icon, width: leadingSize, height: leadingSize),
          if (glyph != null)
            Positioned(
              right: -3,
              bottom: -3,
              child: _Badge(
                color: context.colors.actionButtonBackground,
                child: Icon(glyph, size: 11, color: context.colors.textPrimary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwapIcon(BuildContext context) {
    final isRefund = _isRefundedBtcPeg(transaction!);
    if (isRefund) {
      return SizedBox.square(
        dimension: leadingSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: ClipOval(
                child: SvgPicture.asset(
                  transaction!.fromAsset!.iconPath,
                  width: 34,
                  height: 34,
                ),
              ),
            ),
            Positioned(
              right: -3,
              bottom: -3,
              child: _Badge(
                color: context.appColors.warning,
                // Black on the warning orange keeps the glyph readable in
                // both themes.
                child: Icon(
                  Icons.assignment_return,
                  size: 11,
                  color: context.colors.absoluteBlack,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Two overlapping coins: the sent asset on top left, the received asset
    // on bottom right.
    return SizedBox.square(
      dimension: leadingSize,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 1,
            child: ClipOval(
              child: SvgPicture.asset(
                transaction!.fromAsset!.iconPath,
                width: 27,
                height: 27,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 1,
            child: ClipOval(
              child: SvgPicture.asset(
                transaction!.toAsset!.iconPath,
                width: 27,
                height: 27,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSwapAmount(Asset asset, BigInt amount) {
    if (asset == Asset.usdt) {
      final usdtAmount = amount.toDouble() / 100000000;
      return "\$${usdtAmount.toStringAsFixed(2)}";
    }

    if (asset == Asset.depix) {
      final depixAmount = amount.toDouble() / 100000000;
      return "R\$${depixAmount.toStringAsFixed(2)}";
    }

    return asset.formatBalance(amount);
  }
}

/// A grouped panel of the list: Liquid Glass when [glass] is true, else the
/// plain panel.
class _ListPanel extends StatelessWidget {
  const _ListPanel({
    required this.glass,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  final bool glass;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => glass
      ? GlassPanel(padding: padding, child: child)
      : AppPanel(padding: padding, child: child);
}

/// A small round badge at the corner of a row icon.
///
/// The ring in the panel color separates the badge from the icon below it.
/// In a glass panel, the ring takes the tone of the glass.
class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color:
              GlassPanel.maybeToneOf(context) ??
              AppSurfaces.panel(context).color!,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _LightningTag extends StatelessWidget {
  const _LightningTag();

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            'LN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
