import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_demo_badge.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_icons.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_summary_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_transaction_tile.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Details of one Pix movement.
///
/// The screen states that the record is fictional, so it cannot be read as an
/// official payment receipt.
///
/// The hero is the kind of movement in a neutral well, the signed amount,
/// and the status chip. The details follow in one glass panel.
class PixTransactionDetailScreen extends StatelessWidget {
  final PixTransaction transaction;

  const PixTransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isIncoming =
        transaction.direction == PixTransactionDirection.incoming;
    final failed = transaction.status == PixTransactionStatus.failed;

    return PixScreenScaffold(
      title: t.pix_hub_tx_detail_title,
      appBarActions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Center(child: PixDemoBadge()),
        ),
      ],
      children: [
        Center(
          child: PixIconWell(
            icon: pixTransactionKindIcon(transaction.kind),
            size: 56,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: _HeroAmount(
            amountInCents: transaction.amountInCents,
            // The sign carries the direction, so it never depends on color.
            sign: isIncoming ? '+' : '−',
            color: failed
                ? context.colors.textSecondary
                : isIncoming
                ? context.colors.positiveColor
                : context.colors.textPrimary,
            struckThrough: failed,
          ),
        ),
        const SizedBox(height: 10),
        Center(child: PixStatusChip(status: transaction.status)),
        const SizedBox(height: 28),
        PixSummaryCard(
          entries: [
            PixSummaryEntry(
              isIncoming
                  ? t.pix_hub_summary_payer
                  : t.pix_hub_summary_recipient,
              transaction.counterpartyName,
            ),
            PixSummaryEntry(
              t.pix_hub_summary_type,
              pixTransactionKindLabel(t, transaction.kind),
            ),
            if (transaction.method != null)
              PixSummaryEntry(
                t.pix_hub_summary_method,
                pixSendMethodLabel(t, transaction.method!),
              ),
            if (transaction.description != null)
              PixSummaryEntry(
                t.pix_hub_summary_description,
                transaction.description!,
              ),
            PixSummaryEntry(
              t.pix_hub_summary_date,
              formatPixDateTime(transaction.createdAt),
            ),
            PixSummaryEntry(t.pix_hub_summary_reference, transaction.reference),
          ],
        ),
        const SizedBox(height: 14),
        _Note(text: t.pix_hub_tx_detail_disclaimer),
      ],
    );
  }
}

/// The signed amount of the movement as the hero of the screen.
///
/// The digits are large and use tabular figures. The currency symbol is
/// smaller and muted, so the eye goes to the digits. A long amount or a
/// large text size scales the line down. It never wraps. A failed movement
/// shows the amount struck through, as in the history row.
class _HeroAmount extends StatelessWidget {
  final int amountInCents;
  final String sign;
  final Color color;
  final bool struckThrough;

  const _HeroAmount({
    required this.amountInCents,
    required this.sign,
    required this.color,
    required this.struckThrough,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = formatBrlCents(amountInCents);
    // The format puts a space between the symbol and the digits.
    final split = formatted.indexOf(RegExp(r'\s'));
    final symbol = split < 0 ? '' : formatted.substring(0, split);
    final digits = split < 0 ? formatted : formatted.substring(split + 1);
    final decoration = struckThrough ? TextDecoration.lineThrough : null;

    return Semantics(
      label: '$sign $formatted',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$sign '),
              if (symbol.isNotEmpty)
                TextSpan(
                  text: '$symbol ',
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    decoration: decoration,
                  ),
                ),
              TextSpan(text: digits),
            ],
          ),
          maxLines: 1,
          style: context.textTheme.headlineLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
            decoration: decoration,
          ),
        ),
      ),
    );
  }
}

/// A short explanation at the end of the screen, with an info icon.
class _Note extends StatelessWidget {
  final String text;

  const _Note({required this.text});

  @override
  Widget build(BuildContext context) {
    // Secondary, not tertiary: the tertiary gray fails 4.5:1 on the light
    // page background.
    final color = context.colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
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
      ),
    );
  }
}
