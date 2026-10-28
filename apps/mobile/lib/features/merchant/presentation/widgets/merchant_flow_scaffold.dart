import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/motion/animated_amount.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Returns [reais] in cents. Merchant Mode keeps sale amounts as doubles.
int merchantCents(double reais) => (reais * 100).round();

/// Formats [amountInCents] as reais without the currency symbol, for
/// example `1.234,56`. Reais always use the Brazilian format, whatever the
/// app language.
String merchantBrlDigits(int amountInCents) =>
    NumberFormat('#,##0.00', 'pt_BR').format(amountInCents / 100);

/// Page shell of the steps after Merchant Mode: charge, payment method and
/// payment link.
///
/// It is the page of the Pix flows ([PixScreenScaffold]): the screen
/// backdrop, a clear app bar that names Merchant Mode, a large title, and
/// the content on the 20 pt gutter. The sale amount follows the title as
/// the hero of the screen, so every step of one sale shows the same amount
/// in the same place.
class MerchantFlowScaffold extends StatelessWidget {
  /// Large title of the step.
  final String title;

  /// Optional line below [title].
  final String? subtitle;

  /// The sale amount in BRL cents.
  final int amountInCents;

  /// Optional line below the amount, such as [MerchantHeaderChip]s or a
  /// limit notice.
  final Widget? amountCaption;

  /// Content below the amount. It scrolls when it is taller than the
  /// screen.
  final List<Widget> children;

  /// Main actions, pinned above the bottom edge.
  final Widget? bottomAction;

  /// Full-screen layer over the page, for example the offline notice.
  final Widget? overlay;

  const MerchantFlowScaffold({
    super.key,
    required this.title,
    required this.amountInCents,
    required this.children,
    this.subtitle,
    this.amountCaption,
    this.bottomAction,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final page = PixScreenScaffold(
      appBarTitle: t.merchant_mode_header,
      title: title,
      subtitle: subtitle,
      bottomAction: bottomAction,
      children: [
        MerchantAmountHero(
          label: t.merchant_total_label,
          amountInCents: amountInCents,
        ),
        // A caption that comes or goes, such as a limit notice, grows in
        // and out instead of moving the content at once.
        SizeFadeSwitcher(
          child: amountCaption == null
              ? const SizedBox(
                  key: ValueKey('no-caption'),
                  width: double.infinity,
                )
              : Padding(
                  key: const ValueKey('caption'),
                  padding: const EdgeInsets.only(top: 12),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: amountCaption,
                  ),
                ),
        ),
        const SizedBox(height: 28),
        ...children,
      ],
    );
    if (overlay == null) return page;
    return Stack(
      fit: StackFit.expand,
      children: [
        page,
        // The layer sits outside the page Scaffold, so it brings the text
        // style of a Material. A transparency Material lets taps through
        // while the layer is empty.
        Positioned.fill(
          child: Material(type: MaterialType.transparency, child: overlay),
        ),
      ],
    );
  }
}

/// The sale amount: a label, a muted currency symbol, and large tabular
/// digits.
///
/// It is the amount hero of the Pix payment screen. With [animate], a new
/// amount slides in from the side of the change (see [AnimatedAmount]).
/// Screen readers read the label and the full amount as one node. With
/// [announceChanges], they also announce each new amount.
class MerchantAmountHero extends StatelessWidget {
  const MerchantAmountHero({
    super.key,
    required this.label,
    required this.amountInCents,
    this.animate = false,
    this.announceChanges = false,
    this.centered = false,
    this.amountKey,
  });

  final String label;
  final int amountInCents;

  /// Animates a change of the amount.
  final bool animate;

  /// Makes the hero a live region.
  final bool announceChanges;

  /// Centers the label and the amount.
  final bool centered;

  /// Key of the amount line, for the Merchant Mode tutorial.
  final Key? amountKey;

  @override
  Widget build(BuildContext context) {
    const tabular = [FontFeature.tabularFigures()];
    final digits = merchantBrlDigits(amountInCents);
    final digitsStyle = context.textTheme.displaySmall?.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.8,
      height: 1.1,
      fontFeatures: tabular,
    );
    final symbolStyle = context.textTheme.titleLarge?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w500,
      fontFeatures: tabular,
    );
    final alignment = centered
        ? Alignment.center
        : AlignmentDirectional.centerStart;

    return Semantics(
      label: '$label, ${formatBrlCents(amountInCents)}',
      liveRegion: announceChanges,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          // A long amount or large text shrinks the line instead of
          // overflowing it.
          FittedBox(
            key: amountKey,
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(r'R$', style: symbolStyle),
                const SizedBox(width: 6),
                if (animate)
                  AnimatedAmount(
                    text: digits,
                    value: amountInCents.toDouble(),
                    style: digitsStyle,
                    alignment: AlignmentDirectional.centerEnd,
                  )
                else
                  Text(digits, style: digitsStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A short fact about the sale, below the amount, such as the asset that
/// the merchant receives.
///
/// It is a neutral glass pill. The facts inform, so they leave the brand
/// color to the main action.
class MerchantHeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const MerchantHeaderChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: GlassStyle.of(context).lensFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
