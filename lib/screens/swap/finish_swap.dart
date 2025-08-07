import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/database.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/multichain/swaps_provider.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_input_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_quote_provider.dart';
import 'package:mooze_mobile/screens/swap/widgets/finished_swap_info.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/buttons.dart';
import 'package:url_launcher/url_launcher.dart';

class FinishSwapScreen extends ConsumerStatefulWidget {
  final int quoteId;
  final int ttl;
  final Asset sentAsset;
  final Asset receivedAsset;
  final int sentAmount;
  final int receivedAmount;
  final int fees;

  const FinishSwapScreen({
    super.key,
    required this.quoteId,
    required this.ttl,
    required this.sentAsset,
    required this.receivedAsset,
    required this.sentAmount,
    required this.receivedAmount,
    required this.fees,
  });

  @override
  ConsumerState<FinishSwapScreen> createState() => _FinishSwapScreenState();
}

class _FinishSwapScreenState extends ConsumerState<FinishSwapScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<String?> finishSwap() async {
    final sideswapClient = ref.read(sideswapRepositoryProvider);
    final liquidClient =
        ref.read(liquidWalletRepositoryProvider) as LiquidWalletRepository;

    final quotePset = await sideswapClient.getQuoteDetails(widget.quoteId);
    debugPrint('Quote PSET: $quotePset');

    if (quotePset == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cotação expirada. Tente novamente.')),
        );
      }
      return null;
    }

    final signedPset = await liquidClient.signPsetWithExtraDetails(quotePset);
    debugPrint('Signed PSET: $signedPset');

    final txid = await sideswapClient.signQuote(widget.quoteId, signedPset);
    debugPrint("TXID: $txid");
    sideswapClient.stopQuotes();

    // Insert the swap into the database
    if (txid != null) {
      _saveSwapToDatabase(txid);
    }

    ref.read(swapQuoteNotifierProvider.notifier).stopQuote();
    ref
        .read(swapInputNotifierProvider.notifier)
        .changeSendAssetSatoshiAmount(0);
    ref
        .read(swapInputNotifierProvider.notifier)
        .changeRecvAssetSatoshiAmount(0);
    ref
        .read(swapInputNotifierProvider.notifier)
        .changeSendAsset(AssetCatalog.getById("lbtc")!);
    ref
        .read(swapInputNotifierProvider.notifier)
        .changeRecvAsset(AssetCatalog.getById("depix")!);

    return txid;
  }

  void _saveSwapToDatabase(String txid) async {
    try {
      final database = ref.read(databaseProvider);

      // Create a SwapsCompanion object to insert
      final swapToInsert = SwapsCompanion.insert(
        sendAsset: widget.sentAsset.liquidAssetId ?? widget.sentAsset.id,
        receiveAsset:
            widget.receivedAsset.liquidAssetId ?? widget.receivedAsset.id,
        sendAmount: widget.sentAmount,
        receiveAmount: widget.receivedAmount,
        // createdAt will use the default value (currentDateAndTime)
      );

      // Insert the swap into the database
      final insertedId = await database
          .into(database.swaps)
          .insert(swapToInsert);

      debugPrint('Swap inserted into database with id: $insertedId');
    } catch (e) {
      debugPrint('Error inserting swap into database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoozeAppBar(
        title: "Swap finalizado",
        action: IconButton(
          icon: Icon(Icons.home),
          onPressed: () => Navigator.pushReplacementNamed(context, "/wallet"),
        ),
      ),
      body: FutureBuilder<String?>(
        future: finishSwap(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: const CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao finalizar swap: ${snapshot.error}'),
            );
          }

          final txid = snapshot.data;

          if (txid == null) {
            return Center(child: Text('Erro ao finalizar swap'));
          }

          return Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FinishedSwapInfo(
                          sentAsset: widget.sentAsset,
                          receivedAsset: widget.receivedAsset,
                          sentAmount: widget.sentAmount,
                          receivedAmount: widget.receivedAmount,
                          fees: widget.fees,
                        ),
                        SizedBox(height: 30),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  txid,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 14.5,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondary,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: txid));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "ID copiado para a área de transferência",
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.content_copy_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30),
                        Padding(
                          padding: EdgeInsets.only(bottom: 100),
                          child: PrimaryButton(
                            text: "Abrir no navegador",
                            onPressed: () {
                              launchUrl(
                                Uri.parse(
                                  'https://liquid.network/pt/tx/${txid}',
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
