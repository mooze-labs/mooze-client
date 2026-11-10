import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Hero of the referral screen: what a referral code gives.
///
/// It sits on the screen backdrop, without a card: a gift in a tinted well,
/// the title, the discount as a small pill, and the description. The
/// positive color marks the benefit, on the well and the pill only.
/// Always visible regardless of referral state.
class ReferralInfoCard extends StatelessWidget {
  const ReferralInfoCard({super.key});

  static const double _wellSize = 64;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final positive = context.colors.positiveColor;

    return Column(
      children: [
        Container(
          width: _wellSize,
          height: _wellSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: positive.withValues(alpha: 0.14),
            border: Border.all(color: positive.withValues(alpha: 0.24)),
          ),
          child: Icon(
            Icons.card_giftcard_rounded,
            size: _wellSize / 2,
            color: positive,
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            t.referral_save_title,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: positive.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: positive.withValues(alpha: 0.24)),
          ),
          child: Text(
            t.referral_discount_badge,
            style: context.textTheme.labelMedium?.copyWith(
              color: positive,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t.referral_save_description,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
