import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/referral_provider.dart';
import 'package:mooze_mobile/infra/core/core_sync_helpers.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

// ---------------------------------------------------------------------------
// Fee tier data
// ---------------------------------------------------------------------------

typedef _FeeTier = ({String range, String fee, double min, double max});

// Numeric boundaries are locale-independent; range/fee labels are pulled
// from AppLocalizations at build time so they can be translated.
const _tierBounds = <({double min, double max})>[
  (min: 20, max: 55),
  (min: 55, max: 500),
  (min: 500, max: 3000),
];

List<_FeeTier> _localizedTiers(AppLocalizations t) => [
  (
    range: t.pix_fee_tier1_range,
    fee: t.pix_fee_tier1_value,
    min: _tierBounds[0].min,
    max: _tierBounds[0].max,
  ),
  (
    range: t.pix_fee_tier2_range,
    fee: t.pix_fee_tier2_value,
    min: _tierBounds[1].min,
    max: _tierBounds[1].max,
  ),
  (
    range: t.pix_fee_tier3_range,
    fee: t.pix_fee_tier3_value,
    min: _tierBounds[2].min,
    max: _tierBounds[2].max,
  ),
];

/// Index of the fee tier for [amount], or -1 for no amount. The tier rules
/// run in mooze-core.
int _activeTierIndex(double amount) =>
    CoreSyncHelpers.instance
        .pixFee(amountBrl: amount, hasReferral: false)
        .activeTier ??
    -1;

const _discountColor = Color(0xFF2A9D6B);

// ---------------------------------------------------------------------------
// Card widget
// ---------------------------------------------------------------------------

/// Shows the PIX fee tiers. Collapsed by default to only the tier matching the
/// current deposit amount; tap the header to expand and reveal all tiers and
/// footnotes. When no amount is entered yet, defaults to expanded so the full
/// table is visible. When a referral code is applied, a discount badge appears
/// in the header and a –15% chip is shown on the active tier.
class PixFeeInfoCard extends ConsumerStatefulWidget {
  const PixFeeInfoCard({super.key});

  @override
  ConsumerState<PixFeeInfoCard> createState() => _PixFeeInfoCardState();
}

class _PixFeeInfoCardState extends ConsumerState<PixFeeInfoCard> {
  // null = follow auto behavior (expanded when no active tier yet, collapsed
  // once an amount is entered). Set on first user interaction.
  bool? _userExpanded;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final depositAmount = ref.watch(depositAmountProvider);
    final activeTier = _activeTierIndex(depositAmount);
    final hasReferral = ref.watch(hasReferralProvider).valueOrNull == true;
    final isFixedFee = depositAmount <= fixedFeeRateThreshold;
    // Discount only applies to percentage-based tiers, not the fixed-fee tier.
    final hasDiscount = hasReferral && !isFixedFee;

    final expanded = _userExpanded ?? (activeTier == -1);
    final hasCollapsedContent = activeTier != -1;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: expanded
          ? _expandedBody(context, activeTier, hasDiscount)
          : hasCollapsedContent
          ? _collapsedBody(context, activeTier, hasDiscount)
          : const [SizedBox(width: double.infinity)],
    );

    // A glass panel, like the other summaries of the Pix screens.
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (tappable) ────────────────────────────────────────────
          InkWell(
            onTap:
                () => setState(() {
                  _userExpanded = !expanded;
                }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  PixIcon(
                    PixIcons.percent,
                    size: 14,
                    color: context.colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t.pix_fee_conversion_title,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  if (hasDiscount) ...[
                    const _DiscountBadge(),
                    const SizedBox(width: 8),
                  ],
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: Motion.of(context, Motion.durationBase),
                    curve: Motion.curveMove,
                    child: PixIcon(
                      PixIcons.chevronDown,
                      size: 18,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Animated body ────────────────────────────────────────────────
          // AnimatedSize does not accept a zero duration, so reduced motion
          // shows the new body at once without it.
          if (Motion.isReduced(context))
            body
          else
            AnimatedSize(
              duration: Motion.durationBase,
              curve: Motion.curveMove,
              alignment: Alignment.topCenter,
              child: ClipRect(child: body),
            ),
        ],
      ),
    );
  }

  List<Widget> _expandedBody(
    BuildContext context,
    int activeTier,
    bool hasDiscount,
  ) {
    final t = AppLocalizations.of(context);
    final tiers = _localizedTiers(t);
    return [
      Divider(
        height: 1,
        thickness: 0.5,
        color: AppSurfaces.hairline(context),
      ),
      for (int i = 0; i < tiers.length; i++) ...[
        _TierRow(
          tier: tiers[i],
          isActive: activeTier == i,
          hasDiscount: hasDiscount,
          showFootnoteMarker: true,
        ),
        if (i < tiers.length - 1)
          Divider(
            height: 1,
            thickness: 0.5,
            color: AppSurfaces.hairline(context),
            indent: 16,
            endIndent: 16,
          ),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 3),
        child: Text(
          t.pix_fee_footnote_discount,
          // Secondary, not 35% opacity: the footnotes are fee disclosures
          // and must pass 4.5:1.
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 3, 16, 12),
        child: Text(
          t.pix_fee_footnote_network,
          // Secondary, not 35% opacity: the footnotes are fee disclosures
          // and must pass 4.5:1.
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
    ];
  }

  List<Widget> _collapsedBody(
    BuildContext context,
    int activeTier,
    bool hasDiscount,
  ) {
    final t = AppLocalizations.of(context);
    final tiers = _localizedTiers(t);
    return [
      Divider(
        height: 1,
        thickness: 0.5,
        color: AppSurfaces.hairline(context),
      ),
      _TierRow(
        tier: tiers[activeTier],
        isActive: true,
        hasDiscount: hasDiscount,
        showFootnoteMarker: false,
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Discount badge (header)
// ---------------------------------------------------------------------------

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _discountColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _discountColor.withValues(alpha: 0.30),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PixIcon(PixIcons.tag, size: 11, color: _discountColor),
          const SizedBox(width: 4),
          Text(
            t.pix_fee_discount_active_short,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _discountColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single tier row
// ---------------------------------------------------------------------------

class _TierRow extends StatelessWidget {
  final _FeeTier tier;
  final bool isActive;
  final bool hasDiscount;
  // When false, strips the `*` from the fee text so it doesn't dangle without
  // its footnote (used in the collapsed view where footnotes are hidden).
  final bool showFootnoteMarker;

  const _TierRow({
    required this.tier,
    required this.isActive,
    required this.hasDiscount,
    required this.showFootnoteMarker,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final primary = colorScheme.primary;
    // Show the –15% chip only when this row is the active tier and user has discount.
    final showChip = isActive && hasDiscount;
    final feeText =
        showFootnoteMarker
            ? tier.fee
            : tier.fee.replaceAll('*', '').trimRight();

    return AnimatedContainer(
      duration: Motion.of(context, Motion.durationBase),
      curve: Motion.curveMove,
      // Left padding shrinks by the border width so text stays aligned.
      padding: EdgeInsets.only(
        left: isActive ? 13 : 16,
        right: 16,
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: isActive ? primary.withValues(alpha: 0.07) : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isActive ? primary : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tier.range,
            style: context.textTheme.bodySmall?.copyWith(
              color:
                  isActive
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive && !showChip)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 7),
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                feeText,
                style: context.textTheme.labelMedium?.copyWith(
                  color:
                      isActive
                          ? primary
                          : colorScheme.onSurface.withValues(alpha: 0.65),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (showChip) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _discountColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    AppLocalizations.of(context).pix_fee_discount_chip_15,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: _discountColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
