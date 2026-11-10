import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mooze_mobile/domain/entities/balance.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_glass_section.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' as display;
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Wallet balances of the developer screen.
///
/// Two glass groups: the onchain Bitcoin balance, then the Liquid assets
/// split by hairlines.
class BalanceOverviewCard extends StatelessWidget {
  const BalanceOverviewCard({
    super.key,
    required this.balance,
    required this.loading,
    required this.refreshing,
  });

  final Balance? balance;
  final bool loading;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final breakdown = _BalanceBreakdown.from(balance);
    final showSkeleton = loading && balance == null;
    final showUsdt = breakdown.usdt.amountSat > 0;

    final Widget? status = refreshing
        ? _RefreshIndicator(color: context.colors.textSecondary)
        : balance != null
        ? Text(
            _formatRelativeTime(t, balance!.snapshotAt),
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(title: 'Wallet', trailing: status),
              GlassPanel(
                child: showSkeleton
                    ? const _LoadingRows(count: 1)
                    : _BalanceTile(
                        row: breakdown.onchain,
                        isPrimary: true,
                        locale: locale,
                      ),
              ),
            ],
          ),
        ),
        SettingsGlassSection(
          title: t.developer_liquid_balances,
          child: showSkeleton
              ? const _LoadingRows(count: 2)
              : Column(
                  children: [
                    _BalanceTile(row: breakdown.depix, locale: locale),
                    const PanelDivider(indent: _BalanceTile.textInset),
                    _BalanceTile(row: breakdown.liquid, locale: locale),
                    if (showUsdt) ...[
                      const PanelDivider(indent: _BalanceTile.textInset),
                      _BalanceTile(row: breakdown.usdt, locale: locale),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  static String _formatRelativeTime(AppLocalizations t, DateTime at) {
    if (at.millisecondsSinceEpoch == 0) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 5) return t.developer_time_just_now;
    if (diff.inSeconds < 60) {
      return t.developer_time_seconds_ago(diff.inSeconds);
    }
    if (diff.inMinutes < 60) {
      return t.developer_time_minutes_ago(diff.inMinutes);
    }
    if (diff.inHours < 24) return t.developer_time_hours_ago(diff.inHours);
    return t.developer_time_days_ago(diff.inDays);
  }
}

/// Muted group title with a trailing status, aligned like the title of
/// [SettingsGlassSection].
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _BalanceBreakdown {
  const _BalanceBreakdown({
    required this.onchain,
    required this.depix,
    required this.liquid,
    required this.usdt,
  });

  final _BalanceRowData onchain;
  final _BalanceRowData depix;
  final _BalanceRowData liquid;
  final _BalanceRowData usdt;

  factory _BalanceBreakdown.from(Balance? b) {
    int sumAmount(bool Function(AssetBalance) test) =>
        b?.assets.where(test).fold<int>(0, (a, x) => a + x.amountSat) ?? 0;
    int sumPending(bool Function(AssetBalance) test) =>
        b?.assets.where(test).fold<int>(0, (a, x) => a + x.pendingSat) ?? 0;

    final onchain = _BalanceRowData(
      asset: display.Asset.btc,
      caption: 'Bitcoin mainnet',
      amountSat: sumAmount((a) => a.chain == ChainId.bitcoin),
      pendingSat: sumPending((a) => a.chain == ChainId.bitcoin),
    );

    // Scope Liquid tokens to the LWK (liquid) chain — same as the L-BTC row
    // below. Both LWK and the Breez Liquid SDK report the same Liquid wallet
    // (LWK tagged ChainId.liquid, Breez tagged ChainId.lightning), so matching
    // by assetId alone would sum both sources and double the displayed amount.
    final depix = _BalanceRowData(
      asset: display.Asset.depix,
      caption: 'Liquid asset · BRL stablecoin',
      amountSat: sumAmount(
        (a) => a.chain == ChainId.liquid && a.assetId == display.depixAssetId,
      ),
      pendingSat: 0,
    );

    final liquid = _BalanceRowData(
      asset: display.Asset.lbtc,
      caption: 'LWK · L-BTC',
      amountSat: sumAmount(
        (a) => a.chain == ChainId.liquid && a.assetId == display.lbtcAssetId,
      ),
      pendingSat: sumPending(
        (a) => a.chain == ChainId.liquid && a.assetId == display.lbtcAssetId,
      ),
    );

    final usdt = _BalanceRowData(
      asset: display.Asset.usdt,
      caption: 'Liquid asset · Tether',
      amountSat: sumAmount(
        (a) => a.chain == ChainId.liquid && a.assetId == display.usdtAssetId,
      ),
      pendingSat: 0,
    );

    return _BalanceBreakdown(
      onchain: onchain,
      depix: depix,
      liquid: liquid,
      usdt: usdt,
    );
  }
}

class _BalanceRowData {
  const _BalanceRowData({
    required this.asset,
    required this.caption,
    required this.amountSat,
    required this.pendingSat,
  });

  final display.Asset asset;
  final String caption;
  final int amountSat;
  final int pendingSat;
}

/// One asset row: icon, name and caption, amount and unit.
class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    required this.row,
    required this.locale,
    this.isPrimary = false,
  });

  final _BalanceRowData row;
  final bool isPrimary;
  final String locale;

  static const double _padding = 16;
  static const double _iconSize = 28;
  static const double _iconGap = 14;

  /// Distance from the panel edge to the row text. Dividers start here.
  static const double textInset = _padding + _iconSize + _iconGap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tt = context.textTheme;
    const tabular = [FontFeature.tabularFigures()];

    final amountStyle = (isPrimary ? tt.titleLarge : tt.titleMedium)?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: row.amountSat == 0 ? colors.textSecondary : colors.textPrimary,
      fontFeatures: tabular,
    );

    final amount = row.asset.formatAmount(row.amountSat, locale: locale);
    final unit = row.asset.displayUnit;
    final iconSize = isPrimary ? 32.0 : _iconSize;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _padding,
        vertical: isPrimary ? 18 : 14,
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            row.asset.iconPath,
            width: iconSize,
            height: iconSize,
          ),
          const SizedBox(width: _iconGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.asset.name,
                  style: tt.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.caption,
                  style: tt.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: amountStyle),
              const SizedBox(height: 2),
              Text(
                unit,
                style: tt.labelSmall?.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              if (row.pendingSat > 0) ...[
                const SizedBox(height: 4),
                _PendingLabel(
                  amountSat: row.pendingSat,
                  asset: row.asset,
                  locale: locale,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Pending amount under a balance. The clock is the only status color.
class _PendingLabel extends StatelessWidget {
  const _PendingLabel({
    required this.amountSat,
    required this.asset,
    required this.locale,
  });

  final int amountSat;
  final display.Asset asset;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final formatted = asset.formatAmount(amountSat, locale: locale);
    final unit = asset.displayUnit;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 12,
          color: context.appColors.warning,
        ),
        const SizedBox(width: 4),
        Text(
          '$formatted $unit pending',
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Skeleton rows shown inside a panel while the first balance loads.
class _LoadingRows extends StatefulWidget {
  const _LoadingRows({required this.count});

  final int count;

  @override
  State<_LoadingRows> createState() => _LoadingRowsState();
}

class _LoadingRowsState extends State<_LoadingRows>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Motion.durationShimmer);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.isReduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.appColors.shimmerBase;
    final highlight = context.appColors.shimmerHighlight;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final color = Color.lerp(base, highlight, _c.value)!;
        return Column(
          children: [
            for (int i = 0; i < widget.count; i++) ...[
              if (i > 0) const PanelDivider(indent: _BalanceTile.textInset),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    _box(color, 28, 28, 14),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(color, 100, 12, 4),
                          const SizedBox(height: 8),
                          _box(color, 64, 10, 4),
                        ],
                      ),
                    ),
                    _box(color, 96, 14, 4),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _box(Color color, double w, double h, double r) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}

class _RefreshIndicator extends StatefulWidget {
  const _RefreshIndicator({required this.color});

  final Color color;

  @override
  State<_RefreshIndicator> createState() => _RefreshIndicatorState();
}

class _RefreshIndicatorState extends State<_RefreshIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: Icon(Icons.refresh_rounded, size: 14, color: widget.color),
    );
  }
}
