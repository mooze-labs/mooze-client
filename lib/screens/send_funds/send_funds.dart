import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/screens/send_funds/confirm_send_transaction.dart';
import 'package:mooze_mobile/screens/send_funds/providers/send_user_input_provider.dart';
import 'package:mooze_mobile/screens/send_funds/widgets/current_selected_asset_display.dart';
import 'package:mooze_mobile/screens/send_funds/widgets/fee_rate_display.dart';
import 'package:mooze_mobile/screens/send_funds/widgets/fee_selection_segmented_button.dart';
import 'package:mooze_mobile/screens/send_funds/widgets/selectable_assets_dropdown.dart';
import 'package:mooze_mobile/screens/send_funds/widgets/send_address_input.dart';
import 'package:mooze_mobile/screens/send_funds/widgets/send_amount_input.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/buttons.dart';

class SendFundsScreen extends ConsumerStatefulWidget {
  const SendFundsScreen({super.key});

  @override
  SendFundsScreenState createState() => SendFundsScreenState();
}

class SendFundsScreenState extends ConsumerState<SendFundsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleContinue(WidgetRef ref) async {
    final sendUserInput = ref.read(sendUserInputProvider);
    final ownedAssets = ref.read(ownedAssetsNotifierProvider).value;
    final ownedAsset = ownedAssets?.firstWhere(
      (asset) => asset.asset.id == sendUserInput.asset!.id,
      orElse: () => OwnedAsset.zero(sendUserInput.asset!),
    );

    if (sendUserInput.asset == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Selecione um ativo primeiro.")));
    }

    if (sendUserInput.address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Digite um endereço.")));
    }

    if (sendUserInput.amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Digite um valor para enviar.")));
    }

    if (sendUserInput.networkFee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erro ao calcular taxas de rede. Tente novamente mais tarde.",
          ),
        ),
      );
    }

    if (sendUserInput.amount + sendUserInput.networkFee!.absoluteFees >
        ownedAsset!.amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "O valor inserido excede o saldo disponível + taxas de rede.",
          ),
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ConfirmSendTransactionScreen(
              ownedAsset: ownedAsset,
              address: sendUserInput.address,
              amount: sendUserInput.amount,
              fees: sendUserInput.networkFee?.absoluteFees ?? 100,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoozeAppBar(title: "Enviar ativos"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SelectableAssetsDropdown(),
            Spacer(),
            CurrentSelectedAssetDisplay(),
            Spacer(),
            SendAddressInput(),
            SizedBox(height: 16),
            SendAmountInput(),
            Spacer(),
            FittedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FeeSelectionSegmentedButton(),
                  SizedBox(height: 8),
                  FeeRateDisplay(),
                ],
              ),
            ),
            Spacer(),
            PrimaryButton(
              text: "Revisar transação",
              onPressed: () {
                _handleContinue(ref);
              },
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
