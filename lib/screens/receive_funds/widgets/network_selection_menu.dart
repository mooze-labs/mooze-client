import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/receive_crypto_input.dart';
import '../providers/receive_invoice_provider.dart';

class NetworkSelectionMenu extends ConsumerWidget {
  const NetworkSelectionMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recvInvoice = ref.watch(receiveInvoiceNotifierProvider);

    return DropdownMenu<Network>(
      initialSelection: recvInvoice.network,
      dropdownMenuEntries:
          Network.values
              .map(
                (Network network) => DropdownMenuEntry(
                  value: network,
                  label: network.name.toUpperCase(),
                ),
              )
              .toList(),
      onSelected: (Network? network) {
        ref
            .read(receiveInvoiceNotifierProvider.notifier)
            .updateNetwork(network!);
      },
      trailingIcon: const Icon(Icons.arrow_drop_down),
      inputDecorationTheme:
          Theme.of(context).dropdownMenuTheme.inputDecorationTheme,
    );
  }
}
