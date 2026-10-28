import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_send_draft.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/controllers/pix_send_controller.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_flow_expired_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_send_key_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_summary_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Review step of the send flow.
///
/// The screen shows the withdrawal that the backend created: what the
/// recipient receives, the provider fee, the DePix that leaves the wallet and
/// the Liquid network fee. Confirming broadcasts the DePix deposit. The
/// backend never moves funds by itself.
///
/// The recipient comes first, then one glass panel with the amounts, the
/// fees, and the method. The amount the recipient receives and the DePix
/// debit stand out. The countdown sits right above the confirm button.
class PixSendReviewScreen extends ConsumerStatefulWidget {
  const PixSendReviewScreen({super.key});

  @override
  ConsumerState<PixSendReviewScreen> createState() =>
      _PixSendReviewScreenState();
}

class _PixSendReviewScreenState extends ConsumerState<PixSendReviewScreen> {
  /// Ticks the countdown to the funding cutoff.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _confirm() async {
    final moved = await ref
        .read(pixSendControllerProvider.notifier)
        .confirmAndFund();
    if (!mounted) return;
    if (moved) {
      context.push('/pix/send/result');
      return;
    }
    _showFailure();
  }

  Future<void> _requestNewQuote() async {
    final ready = await ref
        .read(pixSendControllerProvider.notifier)
        .requestQuote();
    if (!mounted || ready) return;
    _showFailure();
  }

  void _showFailure() {
    final failure = ref.read(pixSendControllerProvider).failure;
    if (failure == null) return;
    AppSnackBar.error(
      context,
      pixHubFailureMessage(AppLocalizations.of(context), failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(pixSendControllerProvider);
    final draft = state.draft;
    final quote = state.quote;

    if (draft == null || quote == null) {
      return PixFlowExpiredScaffold(title: t.pix_hub_review_title);
    }

    final remaining = quote.fundingCutoff.difference(DateTime.now());
    final expired = remaining <= Duration.zero;
    final isFunding = state.phase == PixSendPhase.funding;
    final isQuoting = state.phase == PixSendPhase.quoting;
    final withdrawal = quote.withdrawal;
    final networkFee = quote.networkFeeSats;

    return PopScope(
      // Leaving during the broadcast would hide its outcome.
      canPop: !state.isBusy,
      child: PixScreenScaffold(
        appBarTitle: t.pix_hub_send_title,
        title: t.pix_hub_review_title,
        // The deadline sits on top of the button it limits.
        bottomAction: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DeadlineRow(
              cutoff: quote.fundingCutoff,
              remaining: remaining,
              expired: expired,
            ),
            const SizedBox(height: 12),
            if (expired)
              PrimaryButton(
                text: t.pix_hub_review_new_quote,
                isLoading: isQuoting,
                onPressed: _requestNewQuote,
              )
            else
              PrimaryButton(
                text: t.pix_hub_review_confirm,
                isEnabled: quote.canFund,
                isLoading: isFunding,
                onPressed: _confirm,
              ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: state.isBusy ? null : () => context.pop(),
              style: TextButton.styleFrom(
                // A secondary action stays neutral. The brand pink is for
                // the confirm button.
                foregroundColor: context.colors.textPrimary,
                minimumSize: const Size(64, 48),
                textStyle: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(t.pix_hub_review_edit),
            ),
          ],
        ),
        children: [
          // The blocker explains the disabled confirm button, so it leads.
          if (quote.fundingBlocker != null) ...[
            _WarningBanner(
              message: pixHubFailureMessage(t, quote.fundingBlocker!),
            ),
            const SizedBox(height: 20),
          ],
          _Caption(t.pix_hub_summary_recipient),
          const SizedBox(height: 8),
          PixSendKeyCard(draft: draft),
          const SizedBox(height: 16),
          PixSummaryCard(
            entries: [
              PixSummaryEntry(
                t.pix_hub_review_receives,
                formatBrlCents(withdrawal.payoutAmountInCents),
                highlight: true,
              ),
              PixSummaryEntry(
                t.pix_hub_review_provider_fee,
                formatBrlCents(withdrawal.feeInCents),
              ),
              PixSummaryEntry(
                t.pix_hub_review_depix_debit,
                formatDepixUnits(withdrawal.depositAmountSats),
                highlight: true,
              ),
              PixSummaryEntry(
                t.pix_hub_review_network_fee,
                networkFee == null
                    ? t.pix_hub_value_unavailable
                    : t.pix_hub_review_network_fee_value(
                        formatPixInteger(networkFee),
                      ),
              ),
              PixSummaryEntry(
                t.pix_hub_summary_payment_method,
                pixSendMethodLabel(t, draft.method),
              ),
              if (draft.asksForTaxId && draft.taxId != null)
                PixSummaryEntry(
                  t.pix_hub_review_owner_document,
                  _maskedTaxId(draft),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _Note(t.pix_hub_review_disclaimer),
        ],
      ),
    );
  }

  static String _maskedTaxId(PixSendDraft draft) {
    final digits = draft.taxId!;
    return maskPixKey(
      digits.length == 14 ? PixKeyType.cnpj : PixKeyType.cpf,
      digits,
    );
  }
}

/// Small label above a block of the step.
class _Caption extends StatelessWidget {
  final String text;

  const _Caption(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.labelLarge?.copyWith(
        color: context.colors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Funding cutoff and the time left to reach it.
///
/// The countdown uses tabular figures, so the line does not shift every
/// second. An expired quote shows an alert icon and the error color.
class _DeadlineRow extends StatelessWidget {
  final DateTime cutoff;
  final Duration remaining;
  final bool expired;

  const _DeadlineRow({
    required this.cutoff,
    required this.remaining,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = expired
        ? context.colors.negativeColor
        : context.colors.textSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: PixIcon(
            expired ? PixIcons.error : PixIcons.clock,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            expired
                ? t.pix_hub_review_expired
                : '${t.pix_hub_review_deadline(DateFormat('HH:mm').format(cutoff.toLocal()))}'
                      ' · ${t.pix_hub_review_time_left(_format(remaining))}',
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  static String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0
        ? '${d.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}

/// Explains why the wallet cannot fund the withdrawal.
///
/// It sits on the page, not in a glass panel: a tinted banner with an alert
/// icon, so the warning never depends on color alone.
class _WarningBanner extends StatelessWidget {
  final String message;

  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PixIcon(PixIcons.warning, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A secondary note with an info icon.
class _Note extends StatelessWidget {
  final String text;

  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: PixIcon(PixIcons.info, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: color,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
