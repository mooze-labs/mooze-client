import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/providers/pix_history_state_notifier.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/transaction_list.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class PixDepositList extends ConsumerWidget {
  final Function(List<PixDeposit>) filterClosure;
  final bool isVisible;
  final VoidCallback? onRefresh;
  final ScrollController? scrollController;

  const PixDepositList({
    super.key,
    required this.filterClosure,
    required this.isVisible,
    this.scrollController,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pixHistoryNotifierProvider);
    return state.map(
      data: (asyncData) {
        if (asyncData.value.items.isEmpty) return EmptyPixDepositList();
        final deposits = filterClosure(asyncData.value.items);
        return RefreshIndicator(
          onRefresh: () async => onRefresh?.call(),
          child: ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              PixDepositHistoryList(deposits: deposits, isVisible: isVisible),
            ],
          ),
        );
      },
      error: (err) => ErrorPixDepositList(),
      loading: (_) => LoadingPixDepositList(),
    );
  }
}

/// The Pix deposits in the layout of the transaction history: grouped by
/// day under a date header, one glass panel per day, rows split by
/// hairlines.
///
/// Each row is a [HomeTransactionItem], as in the transaction history: the
/// coin of the target asset, the asset name, the status and the time, and
/// the amount. The order of [deposits] stays the same.
class PixDepositHistoryList extends StatelessWidget {
  const PixDepositHistoryList({
    super.key,
    required this.deposits,
    required this.isVisible,
  });

  final List<PixDeposit> deposits;

  /// True when the balance is hidden.
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    final dates = TransactionDates(context, AppLocalizations.of(context));
    final groups = _groupByDay(deposits);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var g = 0; g < groups.length; g++) ...[
          TransactionDateHeader(
            label: dates.day(groups[g].first.createdAt),
            isFirst: g == 0,
          ),
          GlassPanel(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < groups[g].length; i++) ...[
                  if (i > 0)
                    const PanelDivider(indent: HomeTransactionItem.textInset),
                  PixDepositListItem(
                    deposit: groups[g][i],
                    isVisible: isVisible,
                    time: dates.time(groups[g][i].createdAt),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Splits [source] into runs of deposits from the same day.
  static List<List<PixDeposit>> _groupByDay(List<PixDeposit> source) {
    final groups = <List<PixDeposit>>[];
    for (final deposit in source) {
      final day = DateUtils.dateOnly(deposit.createdAt);
      if (groups.isNotEmpty &&
          DateUtils.dateOnly(groups.last.first.createdAt) == day) {
        groups.last.add(deposit);
      } else {
        groups.add([deposit]);
      }
    }
    return groups;
  }
}

/// One Pix deposit as a row of the transaction history.
///
/// The status reads in the line under the asset name, before the time, as
/// in the transaction history. [time] defaults to the day and the time,
/// for a list without date headers.
class PixDepositListItem extends StatelessWidget {
  final PixDeposit deposit;

  /// True when the balance is hidden.
  final bool isVisible;

  final String? time;

  const PixDepositListItem({
    super.key,
    required this.deposit,
    required this.isVisible,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () {
          context.push('/depix/transactions/details', extra: deposit);
        },
        child: HomeTransactionItem(
          icon: deposit.asset.iconPath,
          title: deposit.asset.name,
          subtitle: deposit.status.localizedLabel(context),
          value: '+${formatBrlCents(deposit.amountInCents)}',
          time:
              time ??
              TransactionDates(
                context,
                AppLocalizations.of(context),
              ).dayAndTime(deposit.createdAt),
          isVisible: isVisible,
          // The money of an expired or failed deposit never arrived, so
          // its amount is struck through.
          amountStruck: switch (deposit.status) {
            DepositStatus.expired ||
            DepositStatus.failed ||
            DepositStatus.timeout => true,
            _ => false,
          },
        ),
      ),
    );
  }
}

/// No Pix deposit yet, in the panel of the transaction history's empty
/// state.
class EmptyPixDepositList extends StatelessWidget {
  const EmptyPixDepositList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _PixDepositState(
      icon: Icons.pix_rounded,
      title: t.pix_deposits_empty_title,
      message: t.pix_deposits_empty_message,
    );
  }
}

/// Placeholder rows while the history loads, as in the transaction history.
class LoadingPixDepositList extends StatelessWidget {
  const LoadingPixDepositList({super.key});

  @override
  Widget build(BuildContext context) =>
      const LoadingTransactionList(glass: true);
}

/// The history failed to load, in the panel of the empty state, with a
/// retry button when [onRetry] is set.
class ErrorPixDepositList extends StatelessWidget {
  final VoidCallback? onRetry;

  const ErrorPixDepositList({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _PixDepositState(
      icon: Icons.error_outline_rounded,
      title: t.pix_deposits_load_error_title,
      message: t.pix_deposits_load_error_message,
      onRetry: onRetry,
    );
  }
}

/// A state of the history in a glass panel: an icon, a title, a message,
/// and an optional retry button. It has the layout of the transaction
/// history's empty state.
class _PixDepositState extends StatelessWidget {
  const _PixDepositState({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(icon, color: context.colors.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: context.colors.textPrimary,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
