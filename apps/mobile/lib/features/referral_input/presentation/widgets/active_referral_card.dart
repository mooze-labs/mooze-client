import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The referral code the user already applied, in a glass panel.
///
/// The first row confirms the active discount and shows the code. The
/// second row says what the code gives. The positive color marks the state
/// on the check only.
class ActiveReferralCard extends StatelessWidget {
  final String referralCode;

  const ActiveReferralCard({super.key, required this.referralCode});

  static const double _wellSize = 40;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final positive = context.colors.positiveColor;

    return GlassPanel(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                  child: Icon(Icons.check_rounded, size: 20, color: positive),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.referral_active_title,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.referral_code_with_value(referralCode),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const PanelDivider(indent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.savings_outlined,
                  size: 20,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.referral_savings_message,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
