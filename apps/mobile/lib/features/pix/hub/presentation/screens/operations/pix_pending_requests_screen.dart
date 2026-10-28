import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_empty_state.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_section_header.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_receive_providers.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Charges that are still waiting for a payment.
///
/// The first section lists the real deposits still in progress. Mooze has no
/// endpoint that cancels a deposit, so those rows only open the charge; they
/// close by themselves when the charge expires.
///
/// The second section lists the demonstration payment links, which live on the
/// device and can be removed from the list.
class PixPendingRequestsScreen extends ConsumerWidget {
  const PixPendingRequestsScreen({super.key});

  /// Deposit states that still wait for the payer or for the settlement.
  static const Set<DepositStatus> _inProgress = {
    DepositStatus.pending,
    DepositStatus.underReview,
    DepositStatus.processing,
    DepositStatus.fundsPrepared,
  };

  Future<void> _removeLink(
    BuildContext context,
    WidgetRef ref,
    PixPaymentLink link,
  ) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.pix_hub_pending_remove_title),
        content: Text(t.pix_hub_pending_remove_body(link.reference)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.pix_hub_pending_remove_confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref
        .read(pixHubRepositoryProvider)
        .deletePaymentLink(link.id)
        .run();

    if (!context.mounted) return;
    result.fold(
      (failure) => AppSnackBar.error(context, pixHubFailureMessage(t, failure)),
      (_) {
        ref.invalidate(pixHubPaymentLinksProvider);
        ref.invalidate(pixHubOverviewProvider);
        AppSnackBar.success(context, t.pix_hub_pending_removed);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final deposits = ref.watch(pixDepositHistoryProvider);
    final links = ref.watch(pixHubPaymentLinksProvider);

    return PixScreenScaffold(
      title: t.pix_hub_action_pending,
      onRefresh: () async {
        ref.invalidate(pixDepositHistoryProvider);
        ref.invalidate(pixHubPaymentLinksProvider);
      },
      children: [
        PixSectionHeader(title: t.pix_hub_pending_deposits),
        const SizedBox(height: 4),
        PixSurfaceCard(
          child: deposits.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => PixEmptyState(
              icon: PixIcons.offline,
              title: t.pix_hub_error_title,
              message: t.pix_hub_error_body,
              actionLabel: t.common_retry,
              onAction: () => ref.invalidate(pixDepositHistoryProvider),
              isCompact: true,
            ),
            data: (result) {
              final pending = result
                  .getOrElse((_) => const <PixDeposit>[])
                  .where((deposit) => _inProgress.contains(deposit.status))
                  .toList();

              if (pending.isEmpty) {
                return PixEmptyState(
                  icon: PixIcons.inbox,
                  title: t.pix_hub_pending_deposits_empty_title,
                  message: t.pix_hub_pending_deposits_empty_body,
                  isCompact: true,
                );
              }

              return Column(
                children: [
                  for (final deposit in pending) _DepositRow(deposit: deposit),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.pix_hub_pending_deposits_note,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textTertiary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        PixSectionHeader(title: t.pix_hub_pending_links_section),
        const SizedBox(height: 4),
        PixSurfaceCard(
          child: links.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => PixEmptyState(
              icon: PixIcons.offline,
              title: t.pix_hub_error_title,
              message: t.pix_hub_error_body,
              actionLabel: t.common_retry,
              onAction: () => ref.invalidate(pixHubPaymentLinksProvider),
              isCompact: true,
            ),
            data: (all) {
              final pending = all
                  .where((link) => link.status == PixPaymentLinkStatus.pending)
                  .toList();

              if (pending.isEmpty) {
                return PixEmptyState(
                  icon: PixIcons.linkOff,
                  title: t.pix_hub_empty_links_title,
                  message: t.pix_hub_empty_links_body,
                  isCompact: true,
                );
              }

              return Column(
                children: [
                  for (final link in pending)
                    _LinkRow(
                      link: link,
                      onRemove: () => _removeLink(context, ref, link),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A deposit that is still in progress.
class _DepositRow extends StatelessWidget {
  final PixDeposit deposit;

  const _DepositRow({required this.deposit});

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primaryColor;

    return InkWell(
      onTap: () => context.push('/pix/payment/${deposit.depositId}'),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.schedule_rounded, size: 20, color: primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatBrlCents(deposit.amountInCents),
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${deposit.status.localizedLabel(context)} · '
                    '${formatPixDate(deposit.createdAt)}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// A demonstration payment link that can be removed from the list.
class _LinkRow extends StatelessWidget {
  final PixPaymentLink link;
  final VoidCallback onRemove;

  const _LinkRow({required this.link, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final warning = context.appColors.warning;

    return InkWell(
      onTap: () => context.push('/pix/links/detail', extra: link),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.link_rounded, size: 20, color: warning),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.reference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    link.amountInCents == null
                        ? t.pix_hub_link_open_amount
                        : formatBrlCents(link.amountInCents!),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: t.pix_hub_pending_remove_confirm,
              onPressed: onRemove,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: context.colors.negativeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
