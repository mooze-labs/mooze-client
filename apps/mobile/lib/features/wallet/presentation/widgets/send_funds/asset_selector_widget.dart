import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_picker_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/send_funds/address_controller_provider.dart';
import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/amount_provider.dart';
import '../../providers/send_funds/detected_amount_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import 'balance_card.dart';
import 'send_flow_parts.dart';

void clearAllFields(WidgetRef ref) {
  ref.read(addressControllerProvider).clear();
  ref.read(syncedAddressControllerProvider.notifier).clear();
  ref.read(addressStateProvider.notifier).state = '';

  ref.read(amountStateProvider.notifier).state = 0;
  ref.read(maxSendRequestedProvider.notifier).state = false;
}

/// Assets the user can send, in the order of the picker.
const _sendableAssets = [Asset.lbtc, Asset.btc, Asset.depix, Asset.usdt];

/// Compact choice of the asset to send.
///
/// A glass row shows the asset logo, its name, and its available balance.
/// A tap opens a glass sheet with the assets.
class AssetSelectorWidget extends ConsumerWidget {
  const AssetSelectorWidget({super.key});

  void _select(WidgetRef ref, Asset current, Asset? chosen) {
    if (chosen != null && chosen != current) {
      clearAllFields(ref);
      ref.invalidate(detectedAmountProvider);
      ref.read(selectedAssetProvider.notifier).state = chosen;
    }
  }

  Future<void> _openPicker(
    BuildContext context,
    WidgetRef ref,
    Asset current,
  ) async {
    final t = AppLocalizations.of(context);
    final chosen = await showAssetPickerSheet(
      context,
      title: t.wallet_send_select_asset,
      assets: _sendableAssets,
      selected: current,
    );
    if (!context.mounted) return;
    _select(ref, current, chosen);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final selectedAsset = ref.watch(selectedAssetProvider);
    const radius = BorderRadius.all(Radius.circular(20));

    // One node for screen readers: the purpose, the asset, and the balance.
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: t.wallet_send_select_asset,
        child: PressScale(
          child: SizedBox(
            width: double.infinity,
            child: GlassPanel(
              borderRadius: radius,
              child: InkWell(
                onTap: () => _openPicker(context, ref, selectedAsset),
                borderRadius: radius,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                  child: Row(
                    children: [
                      SendAssetLogo(asset: selectedAsset, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedAsset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleSmall?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const BalanceCard(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PixIcon(
                        PixIcons.chevronDown,
                        size: 18,
                        color: context.colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
