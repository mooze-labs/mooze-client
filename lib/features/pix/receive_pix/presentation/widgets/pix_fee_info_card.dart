import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/referral_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

// ---------------------------------------------------------------------------
// Fee tier data
// ---------------------------------------------------------------------------

typedef _FeeTier = ({String range, String fee, double min, double max});

const _tiers = <_FeeTier>[
  (range: 'R\$ 20 a R\$ 55', fee: 'R\$ 2,00 fixo *', min: 20, max: 55),
  (range: 'R\$ 55 a R\$ 499', fee: '3,5%', min: 55, max: 500),
  (range: 'R\$ 500 a R\$ 3.000', fee: '3% *', min: 500, max: 3000),
];

int _activeTierIndex(double amount) {
  if (amount <= 0) return -1;
  // Tier 0 (fixed fee) matches the same boundary used by fee_rate_provider.
  if (amount <= fixedFeeRateThreshold) return 0;
  // Walk percentage tiers (index 1+) by their upper bound.
  for (int i = 1; i < _tiers.length; i++) {
    if (i == _tiers.length - 1 || amount < _tiers[i].max) return i;
  }
  return -1;
}

const _discountColor = Color(0xFF2A9D6B);
const _expandDuration = Duration(milliseconds: 220);

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
    final depositAmount = ref.watch(depositAmountProvider);
    final activeTier = _activeTierIndex(depositAmount);
    final hasReferral = ref.watch(hasReferralProvider).valueOrNull == true;
    final isFixedFee = depositAmount <= fixedFeeRateThreshold;
    // Discount only applies to percentage-based tiers, not the fixed-fee tier.
    final hasDiscount = hasReferral && !isFixedFee;
    final colorScheme = context.colorScheme;

    final expanded = _userExpanded ?? (activeTier == -1);
    final hasCollapsedContent = activeTier != -1;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.colors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
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
                  Icon(
                    Icons.percent_rounded,
                    size: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Taxas de conversão',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
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
                    duration: _expandDuration,
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Animated body ────────────────────────────────────────────────
          AnimatedSize(
            duration: _expandDuration,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: ClipRect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    expanded
                        ? _expandedBody(context, activeTier, hasDiscount)
                        : hasCollapsedContent
                        ? _collapsedBody(context, activeTier, hasDiscount)
                        : const [SizedBox(width: double.infinity)],
              ),
            ),
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
    final colorScheme = context.colorScheme;
    return [
      Divider(
        height: 1,
        thickness: 0.5,
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
      for (int i = 0; i < _tiers.length; i++) ...[
        _TierRow(
          tier: _tiers[i],
          isActive: activeTier == i,
          hasDiscount: hasDiscount,
          showFootnoteMarker: true,
        ),
        if (i < _tiers.length - 1)
          Divider(
            height: 1,
            thickness: 0.5,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            indent: 16,
            endIndent: 16,
          ),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 3),
        child: Text(
          '* 15% de desconto para usuários com código de indicação.',
          style: context.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.35),
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 3, 16, 12),
        child: Text(
          '* Taxas de rede/spread variável por conta do usuário.',
          style: context.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.35),
            fontStyle: FontStyle.italic,
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
    final colorScheme = context.colorScheme;
    return [
      Divider(
        height: 1,
        thickness: 0.5,
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
      _TierRow(
        tier: _tiers[activeTier],
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
          const Icon(
            Icons.local_offer_rounded,
            size: 11,
            color: _discountColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Desconto ativo',
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
      duration: _expandDuration,
      curve: Curves.easeInOut,
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
                    '−15%',
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
