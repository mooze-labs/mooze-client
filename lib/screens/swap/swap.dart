import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/repositories/sideswap.dart';
import 'package:mooze_mobile/repositories/wallet/liquid.dart';
import 'package:mooze_mobile/screens/pin/verify_pin.dart';
import 'package:mooze_mobile/screens/swap/finish_swap.dart';
import 'package:mooze_mobile/screens/swap/widgets/available_funds.dart';
import 'package:mooze_mobile/screens/swap/widgets/market_dropdown.dart';
import 'package:mooze_mobile/screens/swap/widgets/sideswap_quote_display.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/buttons.dart';

class SwapScreen extends ConsumerStatefulWidget {
  const SwapScreen({super.key});

  @override
  ConsumerState<SwapScreen> createState() => SwapScreenState();
}

class SwapScreenState extends ConsumerState<SwapScreen> {
  final TextEditingController _amountController = TextEditingController();
  double? inputAmount;
  List<SwapUtxo> _swapUtxos = [];

  OwnedAsset? ownedSendAsset;
  Asset? receiveAsset;
  String? baseAsset;
  String? quoteAsset;
  String? assetType;
  SwapDirection swapDirection = SwapDirection.sell;
  int? amount;

  StreamSubscription<QuoteResponse>? _quoteSubscription;
  SideswapQuote? quote;
  QuoteResponse? quoteResponse;
  bool _isLoadingQuote = false;

  @override
  void initState() {
    super.initState();
    final sideswap = ref.read(sideswapRepositoryProvider);
    sideswap.init();

    _quoteSubscription = sideswap.quoteResponseStream.listen((response) {
      setState(() {
        quoteResponse = response;
        if (quoteResponse!.isSuccess) {
          quote = response.quote;
        }
      });

      debugPrint("New quote: ${quote?.quoteId}");
    });
  }

  @override
  void dispose() {
    _quoteSubscription?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void loginToSideswap() {
    final sideswapRepository = ref.read(sideswapRepositoryProvider);
    sideswapRepository.init();
  }

  void onNewMarketSelect(String sendAsset, String recvAsset) async {
    final sideswapRepository = ref.read(sideswapRepositoryProvider);
    final markets = await sideswapRepository.getMarkets();
    final ownedAsset = await getOwnedAsset(
      AssetCatalog.getByLiquidAssetId(sendAsset)!,
    );

    final market = markets.firstWhere(
      (market) =>
          (market.baseAssetId == sendAsset &&
              market.quoteAssetId == recvAsset) ||
          (market.baseAssetId == recvAsset && market.quoteAssetId == sendAsset),
    );

    debugPrint("Market retrieved: ");
    debugPrint("Base: ${market.baseAssetId}");
    debugPrint("Quote: ${market.quoteAssetId}");
    debugPrint("Fee asset: ${market.feeAsset}");
    debugPrint("Type: ${market.type}");

    if (mounted) {
      if (market == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Mercado não disponível")));
      }
    }

    setState(() {
      ownedSendAsset = ownedAsset;
      receiveAsset = AssetCatalog.getByLiquidAssetId(recvAsset)!;
      baseAsset = market.baseAssetId;
      quoteAsset = market.quoteAssetId;
      assetType = (sendAsset == market.quoteAssetId) ? 'Quote' : 'Base';
    });
  }

  Future<List<SwapUtxo>?> fetchUtxos(String assetId, int amount) async {
    int sumAmount = 0;
    final List<SwapUtxo> selectedUtxos = [];

    final liquidWallet =
        ref.read(liquidWalletRepositoryProvider) as LiquidWalletRepository;
    final utxos = await liquidWallet.fetchUtxos();
    final assetUtxos =
        utxos
            .where((utxo) => utxo.unblinded.asset == assetId)
            .map(
              (utxo) => SwapUtxo(
                txid: utxo.outpoint.txid,
                vout: utxo.outpoint.vout,
                value: utxo.unblinded.value.toInt(),
                valueBf: utxo.unblinded.valueBf,
                asset: utxo.unblinded.asset,
                assetBf: utxo.unblinded.assetBf,
              ),
            )
            .toList();

    if (assetUtxos.map((utxo) => utxo.value).fold(0, (a, b) => a + b) <
        amount) {
      return null;
    }

    for (final utxo in assetUtxos) {
      sumAmount += utxo.value;
      selectedUtxos.add(utxo);
      if (sumAmount >= amount) break;
    }

    return selectedUtxos;
  }

  Future<void> requestQuote() async {
    if (baseAsset == null || quoteAsset == null) {
      return;
    }

    final parsedAmount = double.tryParse(_amountController.text);
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor, insira um valor válido.")),
      );
      return;
    }

    setState(() {
      _isLoadingQuote = true;
      quote = null;
      inputAmount = parsedAmount;
    });

    try {
      final sideswapRepository = ref.read(sideswapRepositoryProvider);
      sideswapRepository.stopQuotes();
      final liquidWallet =
          ref.read(liquidWalletRepositoryProvider) as LiquidWalletRepository;
      final sendAsset = assetType! == "Quote" ? quoteAsset! : baseAsset!;

      final receiveAddress = await liquidWallet.generateAddress();
      final changeAddress = await liquidWallet.generateAddress();

      final amount = (parsedAmount * pow(10, 8)).toInt();
      final utxos = await fetchUtxos(sendAsset, amount);

      if (utxos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Fundos insuficientes para realizar o swap."),
            ),
          );
        }
        setState(() {
          _isLoadingQuote = false;
          quote = null;
        });

        return;
      }

      sideswapRepository.startQuote(
        baseAsset: baseAsset!,
        quoteAsset: quoteAsset!,
        assetType: assetType!,
        amount: amount,
        direction: swapDirection,
        utxos: utxos,
        receiveAddress: receiveAddress,
        changeAddress: changeAddress,
      );
    } catch (e) {
      setState(() {
        _isLoadingQuote = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Não foi possível obter uma cotação.")),
        );
      }
    }
  }

  Future<OwnedAsset?> getOwnedAsset(Asset asset) async {
    final ownedAssets = ref.watch(ownedAssetsNotifierProvider);
    return ownedAssets.when(
      loading: () => OwnedAsset.zero(AssetCatalog.getById("depix")!),
      error: (err, stackTrace) {
        debugPrint("Não foi possível obter os ativos");
        return null;
      },
      data:
          (ownedAssets) => ownedAssets.firstWhere(
            (ownedAsset) => ownedAsset.asset.id == asset.id,
            orElse: () => OwnedAsset.zero(AssetCatalog.getById("depix")!),
          ),
    );
  }

  Widget buildQuoteDisplay() {
    if (ownedSendAsset == null) {
      return Container();
    }
    final sideswap = ref.read(sideswapRepositoryProvider);
    return StreamBuilder<QuoteResponse>(
      stream: sideswap.quoteResponseStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        final quoteResponse = snapshot.data!;

        if (quoteResponse.isLowBalance) {
          final quote = quoteResponse.lowBalance!;
          final requestedBalance =
              (ownedSendAsset!.asset.liquidAssetId! == baseAsset!)
                  ? quote.baseAmount
                  : quote.quoteAmount;
          return LowBalanceQuoteDisplay(
            asset: ownedSendAsset!.asset,
            availableBalance: quote.available,
            requestedBalance: requestedBalance,
          );
        }

        if (quoteResponse.isError) {
          final quote = quoteResponse.error!;
          return ErrorQuoteDisplay(errorMessage: quote.errorMessage);
        }

        if (quoteResponse.isSuccess) {
          final receivedQuote = quoteResponse.quote!;
          final requestedBalance =
              (ownedSendAsset!.asset.liquidAssetId! == baseAsset!)
                  ? receivedQuote.quoteAmount
                  : receivedQuote.baseAmount;

          return SuccessfulQuoteAmountDisplay(
            asset: receiveAsset!,
            amount: requestedBalance,
          );
        }

        return Container();
      },
    );
  }

  Widget buildPrimaryButton() {
    if (double.tryParse(_amountController.text) == null) {
      final sideswapClient = ref.read(sideswapRepositoryProvider);
      sideswapClient.stopQuotes();
      return DeactivatedButton(text: "Obter cotação");
    }

    if (quoteResponse == null) {
      return PrimaryButton(
        text: "Obter cotação",
        onPressed: () async => requestQuote(),
      );
    }

    if (double.tryParse(_amountController.text) != inputAmount) {
      return PrimaryButton(
        text: "Obter cotação",
        onPressed: () async => requestQuote(),
      );
    }

    return Column(
      children: [
        PrimaryButton(
          text: "Prosseguir com swap",
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FinishSwapScreen(
                        quoteId: quote!.quoteId,
                        ttl: quote!.ttl,
                        sentAsset: ownedSendAsset!.asset,
                        receivedAsset: receiveAsset!,
                        receivedAmount:
                            (ownedSendAsset!.asset.liquidAssetId! == baseAsset!)
                                ? quote!.quoteAmount
                                : quote!.baseAmount,
                        sentAmount:
                            (ownedSendAsset!.asset.liquidAssetId! == baseAsset!)
                                ? quote!.baseAmount
                                : quote!.quoteAmount,
                        fees: (quote!.fixedFee + quote!.serverFee),
                      ),
                ),
              ),
        ),
      ],
    );
  }

  void _setMaxAmount() {
    _amountController.text =
        "${ownedSendAsset!.amount / pow(10, ownedSendAsset!.asset.precision)}";
  }

  @override
  Widget build(BuildContext context) {
    final sideswap = ref.read(sideswapRepositoryProvider);
    sideswap.init();

    return PopScope(
      child: Scaffold(
        appBar: MoozeAppBar(title: "Swap"),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                MarketDropdown(
                  onMarketSelect:
                      (sendAsset, recvAsset) async =>
                          onNewMarketSelect(sendAsset, recvAsset),
                ),
                const SizedBox(height: 24),
                if (ownedSendAsset != null)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.95,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Digite o valor a enviar",
                        hintStyle: TextStyle(
                          fontFamily: "roboto",
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        suffixIcon:
                            ownedSendAsset != null
                                ? IconButton(
                                  icon: Text(
                                    "MAX",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontFamily: "roboto",
                                    ),
                                  ),
                                  onPressed: () => _setMaxAmount(),
                                )
                                : null,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: "roboto",
                        fontWeight: FontWeight.bold,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                AvailableFunds(asset: ownedSendAsset),
                const SizedBox(height: 24),
                buildQuoteDisplay(),
                Spacer(),
                if (MediaQuery.of(context).viewInsets.bottom == 0)
                  buildPrimaryButton(),
                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
