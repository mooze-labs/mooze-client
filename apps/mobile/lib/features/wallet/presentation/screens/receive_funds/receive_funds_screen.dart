import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/amount_field_receive.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/description_field_receive.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/generate_qr_button.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/network_selector.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_providers.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';

/// Setup step of the receive flow.
///
/// The step reads top to bottom: the asset, its network, the optional
/// amount, and the optional description. The "generate" button stays
/// pinned above the keyboard.
class ReceiveFundsScreen extends ConsumerWidget {
  const ReceiveFundsScreen({super.key});

  void _clearProviders(WidgetRef ref) {
    ref.invalidate(receiveAmountProvider);
    ref.invalidate(receiveAssetValueProvider);
    ref.invalidate(receiveSatsValueProvider);
    ref.invalidate(receiveFiatValueProvider);
    ref.invalidate(receiveDescriptionProvider);
    ref.invalidate(selectedReceiveAssetProvider);
    ref.invalidate(selectedReceiveNetworkProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);

    // The app bar back button pops the route, so this callback clears the
    // receive state for every way out of the screen.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _clearProviders(ref);
      },
      child: PixScreenScaffold(
        title: t.receive_title,
        appBarActions: [
          OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
          IconButton(
            tooltip: t.receive_info_title,
            onPressed: () => _showInfoSheet(context),
            icon: PixIcon(PixIcons.info, size: 22),
          ),
          const SizedBox(width: 4),
        ],
        bottomAction: const GenerateQRButton(),
        children: const [
          AssetSelectorReceive(),
          SizedBox(height: 14),
          NetworkSelector(),
          SizedBox(height: 32),
          AmountFieldReceive(),
          SizedBox(height: 24),
          DescriptionFieldReceive(),
        ],
      ),
    );
  }

  void _showInfoSheet(BuildContext context) {
    final t = AppLocalizations.of(context);
    showGlassInfoSheet(
      context,
      title: t.receive_info_title,
      steps: [
        (t.receive_info_step1_title, t.receive_info_step1_desc),
        (t.receive_info_step2_title, t.receive_info_step2_desc),
        (t.receive_info_step3_title, t.receive_info_step3_desc),
      ],
      hint: t.receive_info_close_hint,
    );
  }
}
