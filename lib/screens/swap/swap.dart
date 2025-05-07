import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/screens/swap/peg_confirm.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_input_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_quote_provider.dart';
import 'package:mooze_mobile/screens/swap/swap_confirm.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_asset_balance.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_asset_card.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_asset_row.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_change_directions.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_peg_warn.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_max_amount_button.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/buttons.dart';

class SideswapScreen extends ConsumerStatefulWidget {
  const SideswapScreen({super.key});

  @override
  ConsumerState<SideswapScreen> createState() => _SideswapScreenState();
}

class _SideswapScreenState extends ConsumerState<SideswapScreen> {
  final TextEditingController sendAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sideswap = ref.read(sideswapRepositoryProvider);
    sideswap.ensureConnection();
    sideswap.stopQuotes();
  }

  @override
  void dispose() {
    super.dispose();
    sendAmountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swapInput = ref.watch(swapInputNotifierProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(sideswapRepositoryProvider).stopQuotes();
        }
      },
      child: Scaffold(
        appBar: MoozeAppBar(title: 'Swap'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),
              FittedBox(
                fit: BoxFit.fitWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Você envia",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          MaxAmountButton(
                            amountController: sendAmountController,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SendAssetRow(amountController: sendAmountController),
                        SizedBox(height: 4),
                        SendAssetBalance(),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              SwapChangeDirections(),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Você recebe",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 4),
                  ReceiveAssetRow(),
                  SizedBox(height: 4),
                  ReceiveAssetBalance(),
                ],
              ),
              Spacer(),
              if (MediaQuery.of(context).viewInsets.bottom == 0)
                PrimaryButton(
                  text: "Continuar",
                  onPressed: () {
                    // Check minimum amounts
                    if (swapInput.recvAsset == AssetCatalog.bitcoin &&
                        swapInput.sendAssetSatoshiAmount < 25000) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'O valor mínimo para receber Bitcoin é 25.000 sats',
                              ),
                            ),
                          );
                        }
                      });
                      return;
                    }

                    if (swapInput.sendAsset == AssetCatalog.bitcoin &&
                        swapInput.sendAssetSatoshiAmount < 10000) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'O valor mínimo para enviar Bitcoin é 10.000 sats',
                              ),
                            ),
                          );
                        }
                      });
                      return;
                    }

                    if (swapInput.sendAsset != AssetCatalog.bitcoin &&
                        swapInput.recvAsset != AssetCatalog.bitcoin) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SwapConfirm()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FinishPegScreen(
                                sendAsset: swapInput.sendAsset,
                                sendAmount: swapInput.sendAssetSatoshiAmount,
                              ),
                        ),
                      );
                    }
                  },
                ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
