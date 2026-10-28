import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_section_header.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/exceptions/user_friendly_exception.dart';
import 'package:mooze_mobile/shared/formatters/fiat_input_formatter.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';

/// Deposit limits of the account, as one quiet glass summary.
///
/// Each limit is a label on the left and its value on the right, split by
/// hairlines, as in the Pix review summaries. While the limits load, the
/// values are skeletons, so the panel keeps its size. A load error shows an
/// alert with a retry inside the same panel.
class AccountLimitsDisplay extends ConsumerWidget {
  /// Shows a "View levels" action next to the title when not null.
  final VoidCallback? onToggleView;

  /// Extra row at the end of the panel, after a hairline, for example the
  /// level of the user.
  final Widget? footer;

  const AccountLimitsDisplay({super.key, this.onToggleView, this.footer});

  static String _brl(double value) =>
      'R\$ ${FiatInputFormatter.formatValue(value)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final levelsData = ref.watch(levelsProvider);
    final dailyLimit = _brl(UserLevelsData.dailyLimit);

    // The rows swap as a whole when the state changes. The key names the
    // state, so a reload of the same state does not animate.
    final rows = levelsData.when(
      data: (data) => Column(
        key: const ValueKey('limits-data'),
        children: [
          _LimitRow(label: t.pix_receive_daily_limit, value: dailyLimit),
          const _Hairline(),
          _LimitRow(
            label: t.pix_receive_per_transaction,
            value: _brl(data.allowedSpending),
          ),
          const _Hairline(),
          _LimitRow(
            label: t.pix_receive_min,
            value: _brl(data.absoluteMinLimit),
          ),
        ],
      ),
      loading: () => Column(
        key: const ValueKey('limits-loading'),
        children: [
          _LimitRow(label: t.pix_receive_daily_limit, value: dailyLimit),
          const _Hairline(),
          _LimitRow(label: t.pix_receive_per_transaction),
          const _Hairline(),
          _LimitRow(label: t.pix_receive_min),
        ],
      ),
      error: (error, stackTrace) => Column(
        key: const ValueKey('limits-error'),
        children: [
          // The daily limit is fixed, so it shows without the levels.
          _LimitRow(label: t.pix_receive_daily_limit, value: dailyLimit),
          const _Hairline(),
          _LimitsError(
            error: error,
            onRetry: () {
              ref.invalidate(walletLevelsRemoteProvider);
              ref.invalidate(userDataProvider);
            },
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixSectionHeader(
          title: t.pix_receive_my_limits,
          actionLabel: onToggleView != null ? t.pix_receive_see_levels : null,
          onAction: onToggleView,
        ),
        const SizedBox(height: 8),
        PixSurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              SizeFadeSwitcher(child: rows),
              if (footer != null) ...[const _Hairline(), footer!],
            ],
          ),
        ),
      ],
    );
  }
}

/// A limit on one line. A null [value] shows a skeleton.
class _LimitRow extends StatelessWidget {
  final String label;
  final String? value;

  const _LimitRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: MergeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (value != null)
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              )
            else
              const SkeletonShimmer(child: SkeletonBox(width: 76, height: 12)),
          ],
        ),
      ),
    );
  }
}

/// Alert shown in the panel when the limits do not load.
///
/// The alert icon, the title, and the warning color mark the state together.
class _LimitsError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _LimitsError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final error = this.error;
    final technical = error is UserFriendlyException
        ? error.getTechnicalMessage()
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: PixIcon(
                    PixIcons.warning,
                    size: 18,
                    color: context.appColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.pix_receive_limits_error,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        error.toString(),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      if (technical != null && kDebugMode)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            t.pix_receive_details(technical),
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.colors.textTertiary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: context.colors.textPrimary,
                minimumSize: const Size(48, 48),
              ),
              icon: const PixIcon(PixIcons.refresh, size: 16),
              label: Text(t.common_retry),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hairline between the rows of the panel, aligned with the row text.
class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: AppSurfaces.hairline(context),
    );
  }
}
