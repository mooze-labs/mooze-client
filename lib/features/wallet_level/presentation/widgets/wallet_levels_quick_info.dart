import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class WalletLevelsQuickInfo extends StatelessWidget {
  final bool isLoading;

  const WalletLevelsQuickInfo({
    super.key,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (isLoading) {
      return _buildLoadingQuickInfo(colorScheme);
    }

    return SizedBox(
      height: 125,
      child: Center(
        child: Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.lock_open_rounded,
                title: 'Desbloqueie',
                subtitle: 'Aumente limites',
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.redeem_rounded,
                title: 'Ganhe',
                subtitle: 'Benefícios extras',
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.star_rate_rounded,
                title: 'Status',
                subtitle: 'Reconhecimento VIP',
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            title,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingQuickInfo(ColorScheme colorScheme) {
    final baseColor = AppColors.baseColor;
    final highlightColor = AppColors.highlightColor;

    return SizedBox(
      height: 125,
      child: Row(
        children: List.generate(
          3,
          (index) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      width: 40,
                      height: 14,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
