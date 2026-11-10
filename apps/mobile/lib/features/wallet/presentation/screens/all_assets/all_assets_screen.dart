import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/all_assets/pinnable_asset_row.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/asset_row.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets/backdrop_page_scaffold.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The markets of every asset, in the rows of the home screen.
///
/// Two groups: the assets pinned to the home screen, with how many of the
/// two places are taken, and the other assets. Each row shows the 24 h
/// sparkline, the price, and the change, and opens the market sheet of the
/// asset. Its star pins or unpins the asset, and the row moves to the other
/// group. A third pin takes the place of the oldest one.
class AllAssetsScreen extends ConsumerWidget {
  const AllAssetsScreen({super.key});

  /// Places on the home screen.
  static const int _maxPinned = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final allAssets = ref.watch(assetsForQuotesProvider);
    final pinned = ref.watch(favoriteAssetsProvider);
    final others = [
      for (final asset in allAssets)
        if (!pinned.contains(asset)) asset,
    ];

    return BackdropPageScaffold(
      title: t.wallet_all_assets_title,
      actions: [
        OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
        const SizedBox(width: 16),
      ],
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          BackdropPageScaffold.gutter,
          8,
          BackdropPageScaffold.gutter,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            t.wallet_all_assets_subtitle,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
          _GroupHeader(
            title: t.wallet_all_assets_pinned,
            trailing: t.wallet_all_assets_favorite_count(pinned.length),
            full: pinned.length >= _maxPinned,
          ),
          // The group grows and shrinks as rows move between the groups.
          SizeFadeSwitcher(
            child: pinned.isEmpty
                ? _EmptyPinned(
                    key: const ValueKey('empty'),
                    text: t.wallet_all_assets_pin_hint,
                  )
                : AssetRowPanel(
                    key: ValueKey(pinned.join()),
                    rows: [
                      for (final asset in pinned)
                        PinnableAssetRow(asset: asset),
                    ],
                  ),
          ),
          if (pinned.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                t.wallet_all_assets_pin_hint,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          if (others.isNotEmpty) ...[
            _GroupHeader(title: t.wallet_all_assets_others),
            SizeFadeSwitcher(
              child: AssetRowPanel(
                key: ValueKey(others.join()),
                rows: [
                  for (final asset in others) PinnableAssetRow(asset: asset),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The title of a group, with an optional count at the end. A full count
/// takes the primary text color, so the limit reads before the next pin.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, this.trailing, this.full = false});

  final String title;
  final String? trailing;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.labelMedium?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(title, style: style)),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: style?.copyWith(
                color: full ? context.colors.textPrimary : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

/// The pinned group without assets: a glass panel with a muted star and
/// the hint.
class _EmptyPinned extends StatelessWidget {
  const _EmptyPinned({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.star_outline_rounded,
            size: 22,
            color: context.colors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
