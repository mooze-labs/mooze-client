import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/exceptions/user_friendly_exception.dart';
import 'package:mooze_mobile/shared/formatters/fiat_input_formatter.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mooze_mobile/shared/extensions.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';

class AccountLimitsDisplay extends ConsumerWidget {
  final VoidCallback? onToggleView;

  const AccountLimitsDisplay({super.key, this.onToggleView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final levelsData = ref.watch(levelsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggleView,
          child: InfoRow(
            label: t.pix_receive_my_limits,
            value: onToggleView != null ? t.pix_receive_see_levels : '',
            labelColor: onSurface,
            valueColor: context.colors.primaryColor,
            fontSize: context.responsiveFont(14),
          ),
        ),
        const SizedBox(height: 10),
        levelsData.when(
          data: (data) => Row(
            children: [
              Expanded(
                child: _buildLimitCard(
                  context,
                  label: t.pix_receive_daily_limit,
                  value: 'R\$ ${FiatInputFormatter.formatValue(UserLevelsData.dailyLimit)}',
                  icon: Icons.calendar_today_rounded,
                  iconColor: context.appColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLimitCard(
                  context,
                  label: t.pix_receive_per_transaction,
                  value: 'R\$ ${FiatInputFormatter.formatValue(data.allowedSpending)}',
                  icon: Icons.swap_horiz_rounded,
                  iconColor: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLimitCard(
                  context,
                  label: t.pix_receive_min,
                  value: 'R\$ ${FiatInputFormatter.formatValue(data.absoluteMinLimit)}',
                  icon: Icons.south_rounded,
                  iconColor: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          error: (error, stackTrace) {
            final warning = context.appColors.warning;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildLimitCard(
                        context,
                        label: t.pix_receive_daily_limit,
                        value: 'R\$ ${FiatInputFormatter.formatValue(UserLevelsData.dailyLimit)}',
                        icon: Icons.calendar_today_rounded,
                        iconColor: context.appColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSkeletonCard(context)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSkeletonCard(context)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: warning.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.pix_receive_limits_error,
                              style: textTheme.labelLarge?.copyWith(
                                color: warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ref.invalidate(levelsProvider),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: warning,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    color: colorScheme.onPrimary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    t.common_retry,
                                    style: textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: textTheme.labelMedium?.copyWith(
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      if (error is UserFriendlyException &&
                          error.getTechnicalMessage() != null &&
                          kDebugMode)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            t.pix_receive_details(
                              error.getTechnicalMessage() ?? '',
                            ),
                            style: textTheme.labelSmall?.copyWith(
                              color: onSurface.withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => Row(
            children: [
              Expanded(child: _buildSkeletonCard(context)),
              const SizedBox(width: 8),
              Expanded(child: _buildSkeletonCard(context)),
              const SizedBox(width: 8),
              Expanded(child: _buildSkeletonCard(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLimitCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final baseColor = context.colors.baseColor;
    final highlightColor = context.colors.highlightColor;
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: 48,
              height: 10,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
