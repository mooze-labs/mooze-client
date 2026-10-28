import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_picker_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/description_field_receive.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_controller.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

final selectedReceiveAssetProvider = StateProvider<Asset?>((ref) => Asset.btc);

/// Assets the wallet can receive, in the order of the picker.
const _receiveAssets = [Asset.btc, Asset.lbtc, Asset.depix, Asset.usdt];

/// Compact glass row that shows the asset to receive.
///
/// A tap opens a floating glass sheet with the assets. A pick there runs
/// the same reset and validation as the previous dropdown.
class AssetSelectorReceive extends ConsumerWidget {
  const AssetSelectorReceive({super.key});

  Future<void> _openPicker(
    BuildContext context,
    WidgetRef ref,
    Asset? selectedAsset,
  ) async {
    final t = AppLocalizations.of(context);
    final picked = await showAssetPickerSheet(
      context,
      title: t.receive_select_asset,
      assets: _receiveAssets,
      selected: selectedAsset,
    );
    // A dismissed sheet changes nothing, as a closed dropdown did.
    if (picked == null || !context.mounted) return;
    _onChanged(ref, selectedAsset, picked);
  }

  void _onChanged(WidgetRef ref, Asset? selectedAsset, Asset? val) {
    final validationController = ref.read(
      receiveValidationControllerProvider.notifier,
    );
    final conversionController = ref.read(
      receiveConversionControllerProvider.notifier,
    );
    final newAsset = val ?? Asset.btc;
    // Switching assets must clear everything that depends on the
    // previous asset — formatters, available conversion modes,
    // validation limits and unit suffixes all differ per asset,
    // so any residual value would surface as invalid or
    // misleading data to the user.
    if (newAsset != selectedAsset) {
      conversionController.resetForAssetChange();
      ref.read(receiveDescriptionProvider.notifier).state = '';
    }
    ref.read(selectedReceiveAssetProvider.notifier).state = newAsset;
    validationController.validateAsset(newAsset);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final selectedAsset = ref.watch(selectedReceiveAssetProvider);
    void open() => _openPicker(context, ref, selectedAsset);

    return Semantics(
      button: true,
      label: t.receive_select_asset,
      value: selectedAsset == null
          ? null
          : '${selectedAsset.ticker}, ${selectedAsset.name}',
      excludeSemantics: true,
      onTap: open,
      child: PressScale(
        child: GlassPanel(
          child: InkWell(
            onTap: open,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                child: Row(
                  children: [
                    if (selectedAsset != null) ...[
                      AssetLensLogo(asset: selectedAsset, size: 40),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: selectedAsset == null
                          ? Text(
                              t.receive_select_asset,
                              style: context.textTheme.bodyLarge?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            )
                          : AssetTickerName(asset: selectedAsset),
                    ),
                    const SizedBox(width: 8),
                    PixIcon(
                      PixIcons.chevronDown,
                      size: 20,
                      color: context.colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
