import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_request.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_demo_badge.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_summary_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:share_plus/share_plus.dart';

/// Shows the charge created by the receive flow.
///
/// The QR Code carries the Copy and Paste payload printed below it. Both are
/// demonstration content: no charge was registered with a Pix provider.
///
/// The amount is the hero. The QR Code sits on its white tile below it, and
/// the code is a copy field. Share is the main action.
class PixPaymentRequestDetailScreen extends StatelessWidget {
  final PixPaymentRequest request;

  const PixPaymentRequestDetailScreen({super.key, required this.request});

  Future<void> _share(BuildContext context) async {
    final t = AppLocalizations.of(context);
    await SharePlus.instance.share(
      ShareParams(text: t.pix_hub_charge_share_message(request.brCode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return PixScreenScaffold(
      title: t.pix_hub_charge_detail_title,
      appBarActions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Center(child: PixDemoBadge()),
        ),
      ],
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            text: t.pix_hub_share,
            onPressed: () => _share(context),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.textPrimary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(
              t.pix_hub_charge_create_another,
              textAlign: TextAlign.center,
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      children: [
        Center(child: _HeroAmount(amountInCents: request.amountInCents)),
        const SizedBox(height: 24),
        PixQrPanel(data: request.brCode, semanticLabel: t.pix_hub_method_qr),
        const SizedBox(height: 28),
        PixCopyField(
          label: t.pix_hub_charge_code_label,
          value: request.brCode,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        PixSummaryCard(
          entries: [
            PixSummaryEntry(
              pixKeyTypeLabel(t, request.key.type),
              request.key.masked,
            ),
            if (request.description != null)
              PixSummaryEntry(
                t.pix_hub_summary_description,
                request.description!,
              ),
            PixSummaryEntry(
              t.pix_hub_summary_created_at,
              formatPixDateTime(request.createdAt),
            ),
            PixSummaryEntry(
              t.pix_hub_summary_expires_at,
              formatPixDateTime(request.expiresAt),
            ),
            PixSummaryEntry(t.pix_hub_summary_reference, request.id),
          ],
        ),
        const SizedBox(height: 14),
        _Note(text: t.pix_hub_charge_disclaimer),
      ],
    );
  }
}

/// The amount of the charge as the hero of the screen.
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
