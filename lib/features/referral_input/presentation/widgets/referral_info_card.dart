import 'package:flutter/material.dart';

/// Promotional card displaying referral program benefits.
///
/// Shows a gift icon, title, discount badge, and description text.
/// Always visible regardless of referral state.
class ReferralInfoCard extends StatelessWidget {
  const ReferralInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final positiveColor = colorScheme.tertiary;
    final onPositive = colorScheme.onTertiary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            positiveColor.withValues(alpha: 0.1),
            positiveColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: positiveColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  positiveColor,
                  Color.lerp(positiveColor, onPositive, 0.25)!,
                ],
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: positiveColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              size: 40,
              color: onPositive,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Economize com indicações!',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: positiveColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ATÉ 15% DE DESCONTO',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: onPositive,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Digite seu código de indicação e aproveite descontos exclusivos em todas as taxas da plataforma.',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
