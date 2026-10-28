import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_icons.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Chip that states the result of a Pix movement.
///
/// The chip carries an icon and a label with its color, so the status
/// never depends on color alone.
class PixStatusChip extends StatelessWidget {
  final PixTransactionStatus status;

  const PixStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (tone, icon) = switch (status) {
      PixTransactionStatus.completed => (PixTone.positive, PixIcons.check),
      PixTransactionStatus.pending => (PixTone.warning, PixIcons.clock),
      PixTransactionStatus.failed => (PixTone.negative, PixIcons.close),
    };
    final color = pixToneColor(context, tone);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixIcon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            pixTransactionStatusLabel(t, status),
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of the Pix history.
///
/// The icon well shows the kind of movement. The amount has a sign, uses
/// tabular figures, and is green for money in. A failed movement shows a
/// struck-through amount and a status chip.
class PixTransactionTile extends StatelessWidget {
  final PixTransaction transaction;
  final VoidCallback? onTap;

  const PixTransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isIncoming =
        transaction.direction == PixTransactionDirection.incoming;
    final failed = transaction.status == PixTransactionStatus.failed;
    final amountColor = failed
        ? context.colors.textTertiary
        : isIncoming
        ? context.colors.positiveColor
        : context.colors.textPrimary;

    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                PixIconWell(icon: pixTransactionKindIcon(transaction.kind)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.counterpartyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pixTransactionKindLabel(t, transaction.kind)} · '
                        '${formatPixDate(transaction.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // The amount gets at most 45% of the row and scales down when
                // it does not fit, so a large amount or large text never
                // overflows. The name gives way first.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.45,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isIncoming ? '+' : '−'} '
                          '${formatBrlCents(transaction.amountInCents)}',
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            decoration: failed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (transaction.status !=
                            PixTransactionStatus.completed) ...[
                          const SizedBox(height: 4),
                          PixStatusChip(status: transaction.status),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
