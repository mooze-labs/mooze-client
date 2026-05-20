import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/description_field_receive.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_controller.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/dropdown_button.dart';

final selectedReceiveAssetProvider = StateProvider<Asset?>((ref) => Asset.btc);

class AssetSelectorReceive extends ConsumerWidget {
  const AssetSelectorReceive({super.key});

  Widget _buildAssetIcon(Asset asset) {
    return SvgPicture.asset(
      asset.iconPath,
      width: 16,
      height: 16,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.watch(selectedReceiveAssetProvider);
    final validationController = ref.read(
      receiveValidationControllerProvider.notifier,
    );
    final conversionController = ref.read(
      receiveConversionControllerProvider.notifier,
    );

    return FloatingLabelDropdown<Asset>(
      label: AppLocalizations.of(context).receive_select_asset,
      value: selectedAsset,
      items: [Asset.btc, Asset.lbtc, Asset.depix, Asset.usdt],
      onChanged: (val) {
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
      },
      itemIconBuilder: _buildAssetIcon,
      itemLabelBuilder: (asset) => asset.name,
      borderColor: Theme.of(context).colorScheme.primary,
    );
  }
}
