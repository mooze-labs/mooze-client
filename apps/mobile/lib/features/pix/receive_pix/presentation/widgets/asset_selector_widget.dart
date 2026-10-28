import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/selected_asset_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/lbtc_warning_provider.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

const _possibleAssets = [Asset.depix, Asset.lbtc];

/// Compact choice of the asset that a Pix deposit delivers.
///
/// The row shows a label and the current asset as a small pill. A tap opens
/// a glass sheet with the assets. The first choice of L-BTC shows the
/// floating rate warning before the selection changes.
class AssetSelectorWidget extends ConsumerWidget {
  const AssetSelectorWidget({super.key});

  Future<bool?> _showLbtcFluctuationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const _LbtcFluctuationDialog(),
    );
  }

  /// Applies [asset] as the deposit asset.
  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    Asset? asset,
  ) async {
    if (asset == Asset.lbtc) {
      final warningService = ref.read(lbtcWarningServiceProvider);
      final hasSeenWarning = await warningService.isWarningShown();
      if (!hasSeenWarning && context.mounted) {
        final dontShowAgain = await _showLbtcFluctuationDialog(context, ref);
        if (dontShowAgain == true) {
          await warningService.setWarningShown();
        }
      }
    }

    ref.read(selectedAssetProvider.notifier).state = (asset ?? Asset.depix);
    ref.invalidate(assetQuoteProvider);
  }

  Future<void> _openPicker(
    BuildContext context,
    WidgetRef ref,
    Asset current,
  ) async {
    final chosen = await showModalBottomSheet<Asset>(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssetPickerSheet(selected: current),
    );
    if (chosen == null || !context.mounted) return;
    await _select(context, ref, chosen);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final selectedAsset = ref.watch(selectedAssetProvider);

    return Semantics(
      button: true,
      label: t.pix_deposit_target_asset,
      value: selectedAsset.name,
      excludeSemantics: true,
      // The screens paint a backdrop over their Material, so the row brings
      // its own surface for the ink.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => _openPicker(context, ref, selectedAsset),
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.pix_deposit_target_asset,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  PressScale(child: _AssetPill(asset: selectedAsset)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The selected asset as a neutral pill: logo, ticker, and a chevron.
class _AssetPill extends StatelessWidget {
  final Asset asset;

  const _AssetPill({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: GlassStyle.of(context).lensFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(asset.iconPath, width: 26, height: 26),
          const SizedBox(width: 8),
          Text(
            asset.ticker,
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          PixIcon(
            PixIcons.chevronDown,
            size: 16,
            color: context.colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

/// Glass sheet that lists the deposit assets.
///
/// It returns the asset that the user taps.
class _AssetPickerSheet extends StatelessWidget {
  final Asset selected;

  const _AssetPickerSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GlassSheet(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: _DragHandle()),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Semantics(
              header: true,
              child: Text(
                t.pix_select_asset,
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final asset in _possibleAssets) ...[
            if (asset != _possibleAssets.first) const SizedBox(height: 6),
            _AssetOption(
              asset: asset,
              isSelected: asset == selected,
              onTap: () => Navigator.of(context).pop(asset),
            ),
          ],
        ],
      ),
    );
  }
}

/// One asset in the sheet.
///
/// The selected row has a lens fill, a brand border, and a check, so the
/// selection never depends on color alone.
class _AssetOption extends StatelessWidget {
  final Asset asset;
  final bool isSelected;
  final VoidCallback onTap;

  const _AssetOption({
    required this.asset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primaryColor;
    const radius = BorderRadius.all(Radius.circular(16));
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: isSelected
                  ? GlassStyle.of(context).lensFill
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? primary : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  SvgPicture.asset(asset.iconPath, width: 36, height: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          asset.ticker,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 10),
                    PixIcon(PixIcons.check, size: 18, color: primary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: context.colorScheme.onSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Warns that L-BTC has a floating rate.
///
/// It returns true when the user asks not to see it again, and false
/// otherwise.
class _LbtcFluctuationDialog extends StatelessWidget {
  const _LbtcFluctuationDialog();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GlassDialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PixIconWell(
              icon: PixIcons.trendingUp,
              tone: PixTone.warning,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              t.pix_floating_rate_title,
              textAlign: TextAlign.center,
              style: context.textTheme.titleLarge?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.pix_floating_rate_body,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: t.common_understood,
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(t.pix_dont_show_again),
            ),
          ],
        ),
      ),
    );
  }
}
