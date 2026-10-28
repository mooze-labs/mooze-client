import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_send_draft.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_icons.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The destination of a Pix send: the key type and the masked key.
///
/// No service names the key owner before the payment, so the card shows the
/// key itself. A name read from a Pix code appears as the code states it.
/// The icon well shows the key type: a document, a company, a phone, an
/// e-mail, or a random key.
class PixSendKeyCard extends StatelessWidget {
  final PixSendDraft draft;

  const PixSendKeyCard({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final merchantName = draft.merchantName;
    return PixSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: MergeSemantics(
          child: Row(
            children: [
              PixIconWell(icon: pixKeyTypeIcon(draft.keyType), size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.maskedKey,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      merchantName == null
                          ? pixKeyTypeLabel(t, draft.keyType)
                          : '${pixKeyTypeLabel(t, draft.keyType)} · '
                                '${t.pix_hub_summary_code_name}: $merchantName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
