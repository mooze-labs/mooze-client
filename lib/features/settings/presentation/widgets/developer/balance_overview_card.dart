import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mooze_mobile/domain/entities/balance.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' as display;
import 'package:mooze_mobile/themes/theme_context_x.dart';

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
    final cs = context.colorScheme;
    final extra = context.appColors;
    final tt = context.textTheme;
    final locale = Localizations.localeOf(context).toString();

    final breakdown = _BalanceBreakdown.from(balance);

    return Container(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: cs.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Wallet',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
              const Spacer(),
              if (refreshing)
                _RefreshIndicator(color: extra.textSecondary)
              else if (balance != null)
                Text(
                  _formatRelativeTime(balance!.snapshotAt),
                  style: tt.bodySmall?.copyWith(color: extra.textTertiary),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading && balance == null)
            const _LoadingRows()
          else ...[
            _BalanceTile(row: breakdown.onchain, isPrimary: true, locale: locale),
            const SizedBox(height: 16),
            _SectionLabel(text: 'L2 Balances'),
            const SizedBox(height: 8),
            _L2Group(
              depix: breakdown.depix,
              liquid: breakdown.liquid,
              usdt: breakdown.usdt,
              locale: locale,
            ),
          ],
        ],
      ),
    );
  }

  static String _formatRelativeTime(DateTime t) {
    if (t.millisecondsSinceEpoch == 0) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
      accent: const Color(0xFFF7931A),
      amountSat: sumAmount((a) => a.chain == ChainId.bitcoin),
      pendingSat: sumPending((a) => a.chain == ChainId.bitcoin),
    );


    final depix = _BalanceRowData(
      asset: display.Asset.depix,
      caption: 'Liquid asset · BRL stablecoin',
      accent: const Color(0xFFBA68C8),
      amountSat: sumAmount((a) => a.assetId == display.depixAssetId),
      pendingSat: 0,
    );

    final liquid = _BalanceRowData(
      asset: display.Asset.lbtc,
      caption: 'LWK · L-BTC',
      accent: const Color(0xFF5BA9E0),
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
      accent: const Color(0xFF26A17B),
      amountSat: sumAmount((a) => a.assetId == display.usdtAssetId),
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
    required this.accent,
    required this.amountSat,
    required this.pendingSat,
  });

  final display.Asset asset;
  final String caption;
  final Color accent;
  final int amountSat;
  final int pendingSat;

  bool get isBitcoinUnit =>
      asset == display.Asset.btc || asset == display.Asset.lbtc;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final extra = context.appColors;
    final tt = context.textTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: tt.bodySmall?.copyWith(
          color: extra.textTertiary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}


class _L2Group extends StatelessWidget {
  const _L2Group({
    required this.depix,
    required this.liquid,
    required this.usdt,
    required this.locale,
  });

  final _BalanceRowData depix;
  final _BalanceRowData liquid;
  final _BalanceRowData usdt;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final showUsdt = usdt.amountSat > 0;

    return Container(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          _BalanceTile(row: depix, isPrimary: false, compact: true, locale: locale),
          _Divider(),
          _BalanceTile(row: liquid, isPrimary: false, compact: true, locale: locale),
          if (showUsdt) ...[
            _Divider(),
            _BalanceTile(row: usdt, isPrimary: false, compact: true, locale: locale),
          ],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      height: 1,
      color: cs.onSurface.withValues(alpha: 0.05),
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    required this.row,
    required this.isPrimary,
    required this.locale,
    this.compact = false,
  });

  final _BalanceRowData row;
  final bool isPrimary;
  final bool compact;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final extra = context.appColors;
    final tt = context.textTheme;

    final amountStyle = (isPrimary ? tt.titleLarge : tt.titleMedium)?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: row.amountSat == 0 ? extra.textSecondary : cs.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final iconSize = isPrimary ? 26.0 : 22.0;
    final chipSize = isPrimary ? 42.0 : 36.0;
    final chipRadius = isPrimary ? 12.0 : 10.0;

    final padding = compact
        ? const EdgeInsets.symmetric(vertical: 10)
        : const EdgeInsets.fromLTRB(2, 2, 2, 4);

    final primary = row.asset.formatAmount(row.amountSat, locale: locale);
    final unit = row.asset.displayUnit;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AssetGlyph(
            iconPath: row.asset.iconPath,
            accent: row.accent,
            size: chipSize,
            radius: chipRadius,
            iconSize: iconSize,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.asset.name,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.caption,
                  style: tt.bodySmall?.copyWith(color: extra.textTertiary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(primary, style: amountStyle),
              const SizedBox(height: 2),
              Text(
                unit,
                style: tt.bodySmall?.copyWith(
                  color: extra.textSecondary,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                ),
              ),
              if (row.pendingSat > 0) ...[
                const SizedBox(height: 4),
                _PendingPill(
                  amountSat: row.pendingSat,
                  accent: row.accent,
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

class _AssetGlyph extends StatelessWidget {
  const _AssetGlyph({
    required this.iconPath,
    required this.accent,
    required this.size,
    required this.radius,
    required this.iconSize,
  });

  final String iconPath;
  final Color accent;
  final double size;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        iconPath,
        width: iconSize,
        height: iconSize,
      ),
    );
  }
}

class _PendingPill extends StatelessWidget {
  const _PendingPill({
    required this.amountSat,
    required this.accent,
    required this.asset,
    required this.locale,
  });

  final int amountSat;
  final Color accent;
  final display.Asset asset;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final formatted = asset.formatAmount(amountSat, locale: locale);
    final unit = asset.displayUnit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 10, color: accent),
          const SizedBox(width: 4),
          Text(
            '$formatted $unit pending',
            style: tt.bodySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingRows extends StatefulWidget {
  const _LoadingRows();

  @override
  State<_LoadingRows> createState() => _LoadingRowsState();
}

class _LoadingRowsState extends State<_LoadingRows>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final alpha = 0.06 + (_c.value * 0.06);
        final color = cs.onSurface.withValues(alpha: alpha);
        return Column(
          children: List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i == 2 ? 0 : 12),
              child: Row(
                children: [
                  _shimmerBox(color, 38, 38, 10),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(color, 100, 12, 4),
                        const SizedBox(height: 8),
                        _shimmerBox(color, 64, 10, 4),
                      ],
                    ),
                  ),
                  _shimmerBox(color, 96, 14, 4),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _shimmerBox(Color color, double w, double h, double r) {
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
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Transform.rotate(
          angle: _c.value * 6.28319,
          child: Icon(Icons.refresh_rounded, size: 14, color: widget.color),
        );
      },
    );
  }
}
