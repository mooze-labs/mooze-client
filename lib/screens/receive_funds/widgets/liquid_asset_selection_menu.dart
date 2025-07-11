import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/models/asset_catalog.dart';

import '../models/receive_crypto_input.dart';
import '../providers/receive_invoice_provider.dart';

class LiquidAssetSelectionMenu extends ConsumerWidget {
  const LiquidAssetSelectionMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recvInvoice = ref.watch(receiveInvoiceNotifierProvider);

    if (recvInvoice.network != Network.liquid) {
      return const SizedBox.shrink();
    }

    return DropdownMenu<String>(
      initialSelection: recvInvoice.assetId,
      dropdownMenuEntries:
          AssetCatalog.liquidAssets
              .map(
                (asset) =>
                    DropdownMenuEntry(value: asset.id, label: asset.name),
              )
              .toList(),
      onSelected: (String? assetId) {
        ref
            .read(receiveInvoiceNotifierProvider.notifier)
            .updateAssetId(assetId!);
      },
      trailingIcon: const Icon(Icons.arrow_drop_down),
      inputDecorationTheme:
          Theme.of(context).dropdownMenuTheme.inputDecorationTheme,
    );
  }
}
