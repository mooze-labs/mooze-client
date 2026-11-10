import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/utils/transaction_display_x.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/conversion_strip.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_detail_scaffold.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_meta_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_status_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail_row.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/hero_amount.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/in_card_action_button.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/utils/formatters.dart';

import '../widgets/send_funds/send_flow_parts.dart';

/// Detail surface for an in-progress peg-in / peg-out.
///
/// Reads the optimistic swap from [pendingSwapsProvider] by [localId]
/// and updates live as the notifier walks through its phase machine.
/// If the swap is reconciled or cleared while this screen is open,
/// the body switches to a "Completed" state pointing the user back
/// home, where the unified swap row in the transaction list takes
/// over the narrative.
///
/// The screen has the layout of the transaction detail: the two coins and
/// the expected amount as the hero, then the status with its track, the
/// conversion strip, a note on the phase, and the identifiers in one glass
/// panel.
class ConvertingDetailsScreen extends ConsumerWidget {
  final String localId;

  const ConvertingDetailsScreen({super.key, required this.localId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swap = ref.watch(
      pendingSwapsProvider.select(
        (list) => list.where((s) => s.localId == localId).firstOrNull,
      ),
    );

    return swap == null ? const _CompletedView() : _ActiveView(swap: swap);
  }
}

class _ActiveView extends ConsumerWidget {
  final PendingSwap swap;
  const _ActiveView({required this.swap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isFailed = swap.phase == PendingSwapPhase.failed;
    // A refundable swap explains its state instead of the phase. Boltz
    // refunds no longer exist, so the note has no action.
    final isRefundable = swap.phase == PendingSwapPhase.refundable;
    final errorMessage = swap.errorMessage;

    return TxDetailScaffold(
      title: t.converting_details_title,
      entranceKey: 'converting-${swap.localId}',
      hero: _Hero(swap: swap),
      sections: [
        _Status(swap: swap, started: _formatDateTime(context, ref)),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ConversionStrip(
            from: ConversionLeg(
              label: t.converting_details_you_sent,
              asset: swap.fromAsset,
              amountInSats: swap.sentAmount,
            ),
            to: ConversionLeg(
              label: t.converting_details_youll_receive,
              asset: swap.toAsset,
              amountInSats: swap.estimatedReceivedAmount,
            ),
          ),
        ),
        if (isFailed && errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SendNotice(
              icon: PixIcons.error,
              tone: PixTone.negative,
              message: errorMessage,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: isRefundable
              ? SendNotice(
                  icon: PixIcons.warning,
                  tone: PixTone.warning,
                  title: t.converting_details_refund_title,
                  message: t.converting_details_refund_message,
                )
              : SendNotice(icon: PixIcons.info, message: _explanation(t, swap)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _Details(swap: swap),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
          child: Text(
            t.converting_details_help_footer,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// The start of the swap as a localized date and time, with the clock
  /// format of the device.
  String _formatDateTime(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeStringProvider);
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final date = DateFormat.yMMMd(locale).format(swap.createdAt);
    final time = (use24h ? DateFormat.Hm(locale) : DateFormat.jm(locale))
        .format(swap.createdAt);
    return AppLocalizations.of(context).tx_detail_datetime(date, time);
  }
}

/// The two coins, "Expected", and the amount the swap should bring in. A
/// failed swap shows the amount struck through.
class _Hero extends ConsumerWidget {
  final PendingSwap swap;
  const _Hero({required this.swap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        HeroSwapIcon(
          fromAsset: swap.fromAsset,
          toAsset: swap.toAsset,
          isRefund: swap.phase == PendingSwapPhase.refundable,
        ),
        const SizedBox(height: 14),
        Text(
          t.tx_detail_expected,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        HeroAmount(
          asset: swap.toAsset,
          amountInSats: swap.estimatedReceivedAmount,
          currencySymbol: ref.watch(currencySymbolProvider),
          struckThrough: swap.phase == PendingSwapPhase.failed,
        ),
      ],
    );
  }
}

/// The phase as a title, the start below it, and the track of the three
/// phases. A failure or a refund takes the place of the step it stopped.
class _Status extends StatelessWidget {
  final PendingSwap swap;
  final String started;
  const _Status({required this.swap, required this.started});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final preparing = t.converting_details_phase_preparing;
    final broadcasting = t.converting_details_phase_broadcasting;
    final awaiting = t.converting_details_phase_awaiting_confirmations;
    const done = TxStepState.done;
    const active = TxStepState.active;
    const upcoming = TxStepState.upcoming;
    const failed = TxStepState.failed;

    final (icon, color, steps) = switch (swap.phase) {
      PendingSwapPhase.preparing => (
        Icons.schedule_rounded,
        context.appColors.warning,
        [
          TxStep(preparing, active),
          TxStep(broadcasting, upcoming),
          TxStep(awaiting, upcoming),
        ],
      ),
      PendingSwapPhase.broadcasting => (
        Icons.schedule_rounded,
        context.appColors.warning,
        [
          TxStep(preparing, done),
          TxStep(broadcasting, active),
          TxStep(awaiting, upcoming),
        ],
      ),
      PendingSwapPhase.broadcasted => (
        Icons.schedule_rounded,
        context.appColors.warning,
        [
          TxStep(preparing, done),
          TxStep(broadcasting, done),
          TxStep(awaiting, active),
        ],
      ),
      PendingSwapPhase.failed => (
        Icons.close_rounded,
        context.colors.negativeColor,
        [
          TxStep(preparing, done),
          TxStep(t.converting_details_phase_failed, failed),
          TxStep(awaiting, upcoming),
        ],
      ),
      PendingSwapPhase.refundable => (
        Icons.priority_high_rounded,
        context.appColors.warning,
        [
          TxStep(preparing, done),
          TxStep(broadcasting, done),
          TxStep(t.converting_details_phase_refundable, failed),
        ],
      ),
    };

    return TxStatusPanel(
      icon: icon,
      title: _phaseLabel(t, swap.phase),
      color: color,
      details: [started],
      steps: steps,
    );
  }
}

/// The direction of the swap, its identifiers, and the block explorer.
class _Details extends StatelessWidget {
  final PendingSwap swap;
  const _Details({required this.swap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final destination = swap.destination;
    final swapId = swap.breezSwapId;
    final txId = swap.breezTxId;
    // The lockup tx lives on the source chain.
    final sourceChain = swap.isPegIn ? Blockchain.bitcoin : Blockchain.liquid;

    return TxMetaPanel(
      cells: [
        MetaCell(
          t.converting_details_direction,
          swap.isPegIn
              ? t.converting_details_direction_peg_in
              : t.converting_details_direction_peg_out,
          wide: true,
        ),
      ],
      ids: [
        if (destination != null)
          DetailRow(
            label: t.converting_details_destination_address,
            value: truncateHashId(destination),
            copyable: true,
            copyValue: destination,
          ),
        if (swapId != null)
          DetailRow(
            label: t.converting_details_swap_id,
            value: truncateHashId(swapId),
            copyable: true,
            copyValue: swapId,
          ),
        if (txId != null)
          DetailRow(
            label: swap.isPegIn
                ? t.converting_details_bitcoin_send_tx
                : t.converting_details_liquid_send_tx,
            value: truncateHashId(txId),
            copyable: true,
            copyValue: txId,
          ),
        DetailRow(label: t.converting_details_local_id, value: swap.localId),
      ],
      links: [
        if (txId != null)
          InCardActionButton(
            label: t.tx_detail_view_send_tx,
            subtitle: sourceChain.shortName,
            icon: Icons.call_made,
            onPressed: () => _openExplorer(txId),
          ),
      ],
    );
  }

  void _openExplorer(String txid) {
    // Lockup tx lives on the SOURCE chain — BDK for peg-in, LWK for
    // peg-out. Blockstream Esplora covers both.
    final url = swap.isPegIn
        ? 'https://blockstream.info/tx/$txid'
        : 'https://blockstream.info/liquid/tx/$txid';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

/// The swap left the pending list: it finished, and the home list now
/// shows it.
class _CompletedView extends StatelessWidget {
  const _CompletedView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SendStatusScaffold(
      status: PixStatusView(
        kind: PixStatusKind.success,
        title: t.converting_details_completed_title,
        message: t.converting_details_completed_message,
      ),
      bottomAction: PrimaryButton(
        text: t.converting_details_back_to_home,
        onPressed: () => context.go('/home'),
      ),
    );
  }
}

String _phaseLabel(AppLocalizations t, PendingSwapPhase phase) {
  switch (phase) {
    case PendingSwapPhase.preparing:
      return t.converting_details_phase_preparing;
    case PendingSwapPhase.broadcasting:
      return t.converting_details_phase_broadcasting;
    case PendingSwapPhase.broadcasted:
      return t.converting_details_phase_awaiting_confirmations;
    case PendingSwapPhase.failed:
      return t.converting_details_phase_failed;
    case PendingSwapPhase.refundable:
      return t.converting_details_phase_refundable;
  }
}

String _explanation(AppLocalizations t, PendingSwap swap) {
  switch (swap.phase) {
    case PendingSwapPhase.preparing:
      return t.converting_details_explanation_preparing;
    case PendingSwapPhase.broadcasting:
      return swap.isPegIn
          ? t.converting_details_explanation_broadcasting_bitcoin
          : t.converting_details_explanation_broadcasting_liquid;
    case PendingSwapPhase.broadcasted:
      return swap.isPegIn
          ? t.converting_details_explanation_broadcasted_peg_in
          : t.converting_details_explanation_broadcasted_peg_out;
    case PendingSwapPhase.failed:
      return t.converting_details_explanation_failed;
    case PendingSwapPhase.refundable:
      return t.converting_details_explanation_refundable;
  }
}
