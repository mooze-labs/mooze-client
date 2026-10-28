import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/controllers/pix_send_controller.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_flow_expired_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_summary_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result of a funded withdrawal.
///
/// The screen reports what the backend states. Only the status `sent` shows
/// a completed payment. A broadcast with an uncertain outcome tells the user
/// not to pay again and keeps reading the status.
///
/// The state emblem, the title, and the message lead. The amount and the
/// recipient follow on the page, then one glass panel with the details and
/// the request ID to copy. "Back to Pix" is the main action. A quieter text
/// action opens the receipt or refreshes the status.
class PixSendResultScreen extends ConsumerWidget {
  const PixSendResultScreen({super.key});

  /// Side margin of the content.
  static const double _gutter = 20;

  void _close(BuildContext context, WidgetRef ref) {
    ref.invalidate(pixPendingWithdrawalsProvider);
    context.go('/pix');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(pixSendControllerProvider);
    final record = state.record;

    if (record == null) {
      return PixFlowExpiredScaffold(title: t.pix_hub_result_title);
    }

    final look = _ResultLook.of(t, state);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !state.isBusy) _close(context, ref);
      },
      child: Scaffold(
        // The app bar is clear and paints its slice of the backdrop. Its
        // back button goes through the pop handler above.
        extendBodyBehindAppBar: true,
        appBar: const BackdropAppBar(),
        body: Stack(
          children: [
            const Positioned.fill(child: AppBackdrop()),
            SafeArea(
              child: _Entrance(
                child: Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref
                            .read(pixSendControllerProvider.notifier)
                            .refreshStatus(),
                        child: ListView(
                          // A pull-to-refresh needs a list that always
                          // scrolls.
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            _gutter,
                            16,
                            _gutter,
                            16,
                          ),
                          children: [
                            PixStatusView(
                              kind: look.kind,
                              title: look.title,
                              message: look.body,
                              child: Column(
                                children: [
                                  _AmountHero(
                                    record: record,
                                    details: state.details,
                                  ),
                                  // The note explains a stopped or failed
                                  // status read next to the emblem.
                                  SizeFadeSwitcher(
                                    child: _StatusNote(state: state),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            _DetailsCard(
                              record: record,
                              details: state.details,
                            ),
                            const SizedBox(height: 12),
                            PixCopyField(
                              label: t.pix_hub_summary_withdrawal_id,
                              value: record.id,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _gutter,
                        8,
                        _gutter,
                        12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PrimaryButton(
                            text: t.pix_hub_back_to_hub,
                            isEnabled: !state.isBusy,
                            onPressed: () => _close(context, ref),
                          ),
                          _SecondaryAction(state: state),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// State emblem and texts of each phase.
class _ResultLook {
  final PixStatusKind kind;
  final String title;
  final String body;

  const _ResultLook(this.kind, this.title, this.body);

  factory _ResultLook.of(AppLocalizations t, PixSendState state) {
    return switch (state.phase) {
      PixSendPhase.completed => _ResultLook(
        PixStatusKind.success,
        t.pix_hub_result_completed_title,
        t.pix_hub_result_completed_body,
      ),
      // A refund closes the payment, and the DePix is back. It informs and
      // asks for no action.
      PixSendPhase.failed
          when state.details?.status == PixWithdrawalStatus.refunded =>
        _ResultLook(
          PixStatusKind.info,
          t.pix_hub_result_failed_title,
          t.pix_hub_result_refunded_body,
        ),
      PixSendPhase.failed => _ResultLook(
        PixStatusKind.failure,
        t.pix_hub_result_failed_title,
        t.pix_hub_result_failed_body,
      ),
      PixSendPhase.outcomeUnknown => _ResultLook(
        PixStatusKind.warning,
        t.pix_hub_result_unknown_title,
        t.pix_hub_result_unknown_body,
      ),
      // The deposit left the wallet, or the broadcast is still running.
      // When the polls stop, a still hourglass replaces the spinner, because
      // nothing checks the status anymore.
      _ => _ResultLook(
        state.pollingExhausted
            ? PixStatusKind.pending
            : PixStatusKind.processing,
        t.pix_hub_result_processing_title,
        t.pix_hub_result_processing_body,
      ),
    };
  }
}

/// The amount the recipient receives and who receives it.
///
/// The amount is the hero: large tabular digits and a muted currency
/// symbol. A screen reader reads it as one value.
class _AmountHero extends StatelessWidget {
  final PixWithdrawalRecord record;
  final PixWithdrawalDetails? details;

  const _AmountHero({required this.record, required this.details});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final amount = formatBrlCents(record.payoutAmountInCents);
    final digits = amount.replaceFirst(r'R$', '').trim();
    final name = details?.receiverName;
    const tabular = [FontFeature.tabularFigures()];

    return Column(
      children: [
        Semantics(
          label: amount,
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                r'R$',
                style: context.textTheme.titleLarge?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  digits,
                  style: context.textTheme.headlineLarge?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    fontFeatures: tabular,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        MergeSemantics(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Text(
                t.pix_hub_summary_recipient,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              Text(
                name ?? record.maskedKey,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (name != null) ...[
          const SizedBox(height: 2),
          Text(
            record.maskedKey,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Status, costs, and identifiers of the withdrawal.
///
/// The amount and the recipient show above, and the request ID has its own
/// copy field below, so the panel lists the other facts only.
class _DetailsCard extends StatelessWidget {
  final PixWithdrawalRecord record;
  final PixWithdrawalDetails? details;

  const _DetailsCard({required this.record, required this.details});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final details = this.details;
    final refund = details?.refund;
    final txid = record.fundingTxid ?? details?.blockchainTxid;

    return PixSummaryCard(
      entries: [
        PixSummaryEntry(
          t.pix_hub_summary_status,
          pixWithdrawalStatusLabel(t, details?.status ?? record.lastStatus),
        ),
        PixSummaryEntry(
          t.pix_hub_review_provider_fee,
          formatBrlCents(record.feeInCents),
        ),
        PixSummaryEntry(
          t.pix_hub_review_depix_debit,
          formatDepixUnits(record.depositAmountSats),
        ),
        if (details?.receiverTaxNumber != null)
          PixSummaryEntry(
            t.pix_hub_summary_document,
            details!.receiverTaxNumber!,
          ),
        if (details?.transferDate != null)
          PixSummaryEntry(
            t.pix_hub_summary_date,
            formatPixDateTime(details!.transferDate!.toLocal()),
          ),
        if (details?.centralBankId != null)
          PixSummaryEntry(
            t.pix_hub_summary_end_to_end,
            details!.centralBankId!,
          ),
        if (refund?.netAmountInCents != null)
          PixSummaryEntry(
            t.pix_hub_summary_refund,
            formatBrlCents(refund!.netAmountInCents!),
          ),
        if (txid != null)
          PixSummaryEntry(t.pix_hub_summary_funding_txid, _short(txid)),
      ],
    );
  }

  static String _short(String value) => value.length <= 20
      ? value
      : '${value.substring(0, 10)}…${value.substring(value.length - 6)}';
}

/// Line about the status reads: failed, stopped, or running.
///
/// A failure or a stop stays on screen while the next read runs, so the
/// line does not blink with each poll. The refresh action shows the
/// progress of a read. On a final state that action is gone, so the line
/// shows the progress instead.
class _StatusNote extends StatelessWidget {
  final PixSendState state;

  const _StatusNote({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = context.colors.textSecondary;

    final (PixIconData?, String)? note;
    if (state.statusFailure != null) {
      note = (PixIcons.offline, t.pix_hub_result_status_error);
    } else if (state.pollingExhausted) {
      note = (PixIcons.clock, t.pix_hub_result_polling_stopped);
    } else if (state.isRefreshing && !_showsRefresh(state)) {
      note = (null, t.pix_hub_withdrawal_status_checking);
    } else {
      note = null;
    }

    if (note == null) {
      return const SizedBox(key: ValueKey('none'), width: double.infinity);
    }
    final (icon, text) = note;
    return Padding(
      key: ValueKey(text),
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: icon == null
                ? SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                      // A still arc when animations are off.
                      value: Motion.isReduced(context) ? 0.7 : null,
                    ),
                  )
                : PixIcon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// True when the screen offers the status refresh: the payment has no
/// final state yet.
bool _showsRefresh(PixSendState state) =>
    state.phase != PixSendPhase.completed && state.phase != PixSendPhase.failed;

/// Receipt link when the Pix is delivered, else a status refresh.
///
/// Both are text buttons below the main action, so they stay secondary.
class _SecondaryAction extends ConsumerWidget {
  final PixSendState state;

  const _SecondaryAction({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final receipt = Uri.tryParse(state.details?.receiptUrl ?? '');

    if (state.phase == PixSendPhase.completed &&
        receipt != null &&
        receipt.isScheme('https')) {
      return _QuietButton(
        icon: PixIcons.externalLink,
        label: t.pix_hub_result_receipt,
        onPressed: () =>
            launchUrl(receipt, mode: LaunchMode.externalApplication),
      );
    }

    if (_showsRefresh(state)) {
      return _QuietButton(
        icon: PixIcons.refresh,
        label: t.pix_hub_result_refresh,
        isLoading: state.isRefreshing,
        onPressed: state.isBusy || state.isRefreshing
            ? null
            : () =>
                  ref.read(pixSendControllerProvider.notifier).refreshStatus(),
      );
    }

    return const SizedBox.shrink();
  }
}

/// A neutral text button with a leading icon, 48 pt high.
///
/// While [isLoading] is true, a small spinner replaces the icon.
class _QuietButton extends StatelessWidget {
  final PixIconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _QuietButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null
        ? context.colors.textTertiary
        : context.colors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: context.colors.textPrimary,
          minimumSize: const Size(double.infinity, 48),
          textStyle: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: isLoading
            ? SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                  value: Motion.isReduced(context) ? 0.7 : null,
                ),
              )
            : PixIcon(icon, size: 18, color: color),
        label: Text(label),
      ),
    );
  }
}

/// Fades and raises the content once, when the screen opens.
///
/// It runs over [Motion.durationBase], as the entrance of the other Pix
/// screens. With reduced motion, the content appears at once.
class _Entrance extends StatefulWidget {
  const _Entrance({required this.child});

  final Widget child;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationBase,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Motion.curveEnter,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      if (Motion.isReduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(animation: _animation, child: widget.child);
  }
}
