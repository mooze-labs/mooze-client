import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import '../providers/send_user_input_provider.dart';
import '../widgets/inputs.dart';

class SendAddressInput extends ConsumerWidget {
  const SendAddressInput({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();

    return AddressInput(
      controller: amountController,
      onAddressChanged:
          (String address) =>
              ref.read(sendUserInputProvider.notifier).setAddress(address),
      onAssetSelected:
          (Asset asset) =>
              ref.read(sendUserInputProvider.notifier).setAsset(asset),
    );
  }
}
