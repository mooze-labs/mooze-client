import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/links/pix_payment_links_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_demo_badge.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_summary_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:share_plus/share_plus.dart';

/// Details of one payment link, with the actions to copy and to share it.
///
/// The amount is the hero, with the status chip below it. The QR Code of
/// the link address sits on its white tile, and the address is a copy
/// field. Share is the main action.
class PixPaymentLinkDetailScreen extends StatelessWidget {
  final PixPaymentLink link;

  const PixPaymentLinkDetailScreen({super.key, required this.link});

  Future<void> _share(BuildContext context) async {
    final t = AppLocalizations.of(context);
    await SharePlus.instance.share(
      ShareParams(text: t.pix_hub_link_share_message(link.url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return PixScreenScaffold(
      title: t.pix_hub_link_detail_title,
      appBarActions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Center(child: PixDemoBadge()),
        ),
      ],
      bottomAction: PrimaryButton(
        text: t.pix_hub_share,
        onPressed: () => _share(context),
      ),
      children: [
        Center(child: _HeroAmount(amountInCents: link.amountInCents)),
        const SizedBox(height: 10),
        Center(child: PixPaymentLinkStatusChip(status: link.status)),
        const SizedBox(height: 24),
        PixQrPanel(data: link.url, semanticLabel: t.pix_hub_method_qr),
        const SizedBox(height: 28),
        PixCopyField(
          label: t.pix_hub_link_url_label,
          value: link.url,
          icon: PixIcons.link,
        ),
        const SizedBox(height: 24),
        PixSummaryCard(
          entries: [
            PixSummaryEntry(t.pix_hub_link_reference_label, link.reference),
            PixSummaryEntry(
              t.pix_hub_link_usage_label,
              link.singleUse
                  ? t.pix_hub_link_single_use
                  : t.pix_hub_link_reusable,
            ),
            PixSummaryEntry(
              t.pix_hub_summary_created_at,
              formatPixDateTime(link.createdAt),
            ),
            if (link.paidAt != null)
              PixSummaryEntry(
                t.pix_hub_link_paid_at,
                formatPixDateTime(link.paidAt!),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _Note(text: t.pix_hub_link_disclaimer),
      ],
    );
  }
}

/// The amount of the link as the hero of the screen.
///
/// The digits are large and use tabular figures. The currency symbol is
/// smaller and muted, so the eye goes to the digits. A long amount or a
/// large text size scales the line down. It never wraps.
class _HeroAmount extends StatelessWidget {
  /// Amount in BRL cents, or null when the payer informs the amount.
  final int? amountInCents;

  const _HeroAmount({required this.amountInCents});

  @override
  Widget build(BuildContext context) {
    final cents = amountInCents;
    if (cents == null) {
      return Text(
        AppLocalizations.of(context).pix_hub_link_open_amount,
        textAlign: TextAlign.center,
        style: context.textTheme.headlineSmall?.copyWith(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final formatted = formatBrlCents(cents);
    // The format puts a space between the symbol and the digits.
    final split = formatted.indexOf(RegExp(r'\s'));
    final symbol = split < 0 ? '' : formatted.substring(0, split);
    final digits = split < 0 ? formatted : formatted.substring(split + 1);

    return Semantics(
      label: formatted,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            children: [
              if (symbol.isNotEmpty)
                TextSpan(
                  text: '$symbol ',
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              TextSpan(text: digits),
            ],
          ),
          maxLines: 1,
          style: context.textTheme.headlineLarge?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
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
