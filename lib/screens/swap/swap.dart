import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/providers/peg_operation_provider.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/repositories/wallet/liquid.dart';
import 'package:mooze_mobile/screens/swap/check_peg_status.dart';
import 'package:mooze_mobile/screens/swap/confirm_peg.dart';
import 'package:mooze_mobile/screens/swap/finish_swap.dart';
import 'package:mooze_mobile/screens/swap/widgets/available_funds.dart';
import 'package:mooze_mobile/screens/swap/widgets/market_dropdown.dart';
import 'package:mooze_mobile/screens/swap/widgets/peg_available_funds.dart';
import 'package:mooze_mobile/screens/swap/widgets/server_status.dart';
import 'package:mooze_mobile/screens/swap/widgets/peg_input_display.dart';
import 'package:mooze_mobile/screens/swap/widgets/sideswap_quote_display.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/buttons.dart';
import 'package:mooze_mobile/widgets/swipe_to_confirm.dart';

class SideswapScreen extends ConsumerStatefulWidget {
  const SideswapScreen({super.key});

  @override
  ConsumerState<SideswapScreen> createState() => SideswapScreenState();
}

class SideswapScreenState extends ConsumerState<SideswapScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [SwapScreen(), PegScreen()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Swap'),
          BottomNavigationBarItem(
            icon: Icon(Icons.cached),
            label: 'Peg-in/out',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.tertiary,
        onTap: _onItemTapped,
      ),
    );
  }
}

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

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    final sideswapRepository = ref.read(sideswapRepositoryProvider);
    sideswapRepository.init();

    _quoteSubscription = sideswapRepository.quoteResponseStream.listen((
      response,
    ) {
      if (mounted) updateQuoteState(response);
    });
  }

  @override
  void dispose() {
    _quoteSubscription?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _checkConnection() {
    final sideswapClient = ref.read(sideswapRepositoryProvider);
    final connected = sideswapClient.ensureConnection();

    if (!connected && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Falha na conexão com Sideswap. Tentando reconectar...',
          ),
          duration: Duration(seconds: 3),
        ),
      );

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          sideswapClient.init();
        }
      });
    }
  }

  void updateQuoteState(QuoteResponse response) {
    setState(() {
      quoteResponse = response;

      if (response.isSuccess) {
        quote = response.quote;
        _isLoadingQuote = false;
      } else if (response.isError) {
        quote = null;
        _isLoadingQuote = false;
      } else if (response.isLowBalance) {
        quote = null;
        _isLoadingQuote = false;
      }
    });

    debugPrint("Quote state updated: ${quote?.quoteId ?? 'No quote'}");
  }

  void loginToSideswap() {
    final sideswapRepository = ref.read(sideswapRepositoryProvider);
    sideswapRepository.init();
  }

  void onNewMarketSelect(String sendAsset, String recvAsset) async {
    debugPrint("Market selection changed: $sendAsset → $recvAsset");

    final sideswapRepository = ref.read(sideswapRepositoryProvider);
    sideswapRepository.stopQuotes();

    setState(() {
      quote = null;
      quoteResponse = null;
      _amountController.text = "";
      inputAmount = null;
      _isLoadingQuote = false;
    });

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

    if (market == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Mercado não disponível")));
      }
      return;
    }

    debugPrint("Market retrieved: ");
    debugPrint("Base: ${market.baseAssetId}");
    debugPrint("Quote: ${market.quoteAssetId}");
    debugPrint("Fee asset: ${market.feeAsset}");
    debugPrint("Type: ${market.type}");

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

    final parsedAmount = double.tryParse(
      _amountController.text.replaceAll(",", "."),
    );
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor, insira um valor válido.")),
      );
      return;
    }

    setState(() {
      _isLoadingQuote = true;
      quote = null;
      quoteResponse = null;
      inputAmount = parsedAmount;
    });

    try {
      final sideswapRepository = ref.read(sideswapRepositoryProvider);
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

  Widget buildPrimaryButton() {
    if (baseAsset == null || quoteAsset == null || ownedSendAsset == null) {
      return DeactivatedButton(text: "Obter cotação");
    }

    final currentText = _amountController.text;
    final parsedAmount = double.tryParse(currentText.replaceAll(",", "."));
    if (parsedAmount == null || parsedAmount <= 0) {
      final sideswapClient = ref.read(sideswapRepositoryProvider);
      sideswapClient.stopQuotes();
      return DeactivatedButton(text: "Obter cotação");
    }

    if (_isLoadingQuote) {
      return Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text("Obtendo cotação..."),
          ],
        ),
      );
    }

    if (quoteResponse == null ||
        inputAmount == null ||
        (parsedAmount - inputAmount!).abs() > 0.000001) {
      return PrimaryButton(
        text: "Obter cotação",
        onPressed: () => requestQuote(),
      );
    }

    if (quoteResponse!.isSuccess && quote != null) {
      return Column(
        children: [
          SwipeToConfirm(
            text: "Realizar swap",
            onConfirm:
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
                              (ownedSendAsset!.asset.liquidAssetId! ==
                                      baseAsset!)
                                  ? quote!.quoteAmount
                                  : quote!.baseAmount,
                          sentAmount:
                              (ownedSendAsset!.asset.liquidAssetId! ==
                                      baseAsset!)
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

    return PrimaryButton(
      text: "Obter cotação",
      onPressed: () => requestQuote(),
    );
  }

  Widget buildQuoteDisplay() {
    if (ownedSendAsset == null) {
      return Container();
    }

    if (quote == null && !_isLoadingQuote) {
      return Container();
    }

    if (_isLoadingQuote) {
      return Container(
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text("Obtendo cotação..."),
            ],
          ),
        ),
      );
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
          return Container(
            height: 150,
            child: LowBalanceQuoteDisplay(
              asset: ownedSendAsset!.asset,
              availableBalance: quote.available,
              requestedBalance: requestedBalance,
            ),
          );
        }

        if (quoteResponse.isError) {
          final quote = quoteResponse.error!;
          return Container(
            height: 150,
            child: ErrorQuoteDisplay(errorMessage: quote.errorMessage),
          );
        }

        if (quoteResponse.isSuccess) {
          final receivedQuote = quoteResponse.quote!;
          final requestedBalance =
              (ownedSendAsset!.asset.liquidAssetId! == baseAsset!)
                  ? receivedQuote.quoteAmount
                  : receivedQuote.baseAmount;

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                child: SuccessfulQuoteAmountDisplay(
                  asset: receiveAsset!,
                  amount: requestedBalance,
                ),
              ),
              if (MediaQuery.of(context).viewInsets.bottom == 0)
                buildPrimaryButton(),
            ],
          );
        }

        return Container();
      },
    );
  }

  void _setMaxAmount() {
    final maxAmount =
        ownedSendAsset!.amount / pow(10, ownedSendAsset!.asset.precision);
    _amountController.text = "$maxAmount";

    setState(() {
      inputAmount = maxAmount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sideswap = ref.read(sideswapRepositoryProvider);
    sideswap.init();

    return Scaffold(
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
              Expanded(child: buildQuoteDisplay()),
              if (quote == null) buildPrimaryButton(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class PegScreen extends ConsumerStatefulWidget {
  const PegScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PegScreen> createState() => _PegScreenState();
}

class _PegScreenState extends ConsumerState<PegScreen> {
  Future<ServerStatus?>? serverStatus;
  Set<bool> pegIn = {true};
  OwnedAsset? asset;
  OwnedAsset? bitcoin;
  OwnedAsset? liquid;

  bool sendToExternalWallet = false;
  bool receiveFromExternalWallet = false;

  final TextEditingController addressController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sideswapClient = ref.read(sideswapRepositoryProvider);

    sideswapClient.subscribeToPegInWalletBalance();
    sideswapClient.subscribeToPegOutWalletBalance();

    serverStatus = sideswapClient.getServerStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActivePegOperation();
    });
  }

  Future<void> _checkActivePegOperation() async {
    final activePegOp = await ref.read(activePegOperationProvider.future);

    if (kDebugMode) {
      debugPrint("Active peg operation: $activePegOp");
    }

    if (activePegOp != null && mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text("Operação em andamento"),
              content: Text(
                'Você tem uma operação de ${activePegOp.isPegIn ? 'peg-in' : 'peg-out'} em andamento. Deseja verificar o status?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Não'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CheckPegStatusScreen(
                              pegIn: activePegOp.isPegIn,
                              orderId: activePegOp.orderId,
                            ),
                      ),
                    );
                  },
                  child: Text('Sim'),
                ),
              ],
            ),
      );
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _setMaxAmount() {
    if (asset == null) return;

    amountController.text =
        "${asset!.amount / pow(10, asset!.asset.precision)}";
  }

  void refreshAll() {
    final sideswapClient = ref.read(sideswapRepositoryProvider);

    sideswapClient.subscribeToPegInWalletBalance();
    sideswapClient.subscribeToPegOutWalletBalance();

    // Refresh server status
    setState(() {
      serverStatus = sideswapClient.getServerStatus();
    });
  }

  Future<void> getBalance() async {
    final ownedAssets = ref.watch(ownedAssetsNotifierProvider);
    return ownedAssets.when(
      loading: () => null,
      error: (err, stackTrace) {
        debugPrint("Não foi possível obter o saldo atual.");
        return null;
      },
      data: (ownedAssets) {
        final bitcoin = ownedAssets.firstWhere(
          (ownedAsset) => ownedAsset.asset.id == "btc",
        );
        final liquid = ownedAssets.firstWhere(
          (ownedAsset) => ownedAsset.asset.id == "lbtc",
        );

        setState(() {
          this.bitcoin = bitcoin;
          this.liquid = liquid;
        });
      },
    );
  }

  Future<bool> checkFunds(int minAmount) async {
    final ownedAssets = ref.watch(ownedAssetsNotifierProvider);
    return ownedAssets.when(
      loading: () => false,
      error: (err, stackTrace) => false,
      data: (ownedAssets) {
        final bitcoin = ownedAssets.firstWhere(
          (ownedAsset) => ownedAsset.asset.id == "btc",
        );
        final liquid = ownedAssets.firstWhere(
          (ownedAsset) => ownedAsset.asset.id == "lbtc",
        );

        final parsedBalance = double.tryParse(
          amountController.text.replaceAll(",", "."),
        );
        if (parsedBalance == null) {
          return false;
        }

        final amountInSats = (parsedBalance * pow(10, 8)).toInt();
        final pegAsset = pegIn.first ? bitcoin : liquid;

        if (kDebugMode) {
          debugPrint("Written amount: $amountInSats");
          debugPrint("Peg asset: ${pegAsset.asset.id}");
          debugPrint("Amount in wallet: ${pegAsset.amount}");
        }

        if (pegAsset.amount < amountInSats) {
          debugPrint("1");
          return false;
        }

        if (amountInSats < minAmount && !receiveFromExternalWallet) {
          debugPrint("2");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Valor menor que o mínimo permitido."),
              duration: Duration(seconds: 2),
            ),
          );

          return false;
        }

        /*
        if (balanceInSats > maxAmount) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text("Valor maior que o máximo permitido."),
                  content: Text(
                    "Você inseriu um valor maior que o máximo permitido pelo servidor. Você pode prosseguir com uma transação, mas com a possibilidade de demorar mais que 2 horas. Continuar?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text("Continuar mesmo assim"),
                    ),
                  ],
                ),
          );
        }
        */
        this.asset = pegAsset;
        return true;
      },
    );
  }

  Future<void> validateAndRedirect() async {
    final serverStatus = await this.serverStatus;

    if (serverStatus == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Não foi possível conectar ao servidor."),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    final minAmount =
        (pegIn.first)
            ? serverStatus!.minPegInAmount
            : serverStatus!.minPegOutAmount;
    final fundsValidation = await checkFunds(minAmount);

    if (!fundsValidation) {
      if (mounted) {
        if (!receiveFromExternalWallet && pegIn.first == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("BTC insuficientes."),
              duration: Duration(seconds: 2),
            ),
          );

          return;
        }

        if (pegIn.first == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("L-BTC insuficientes."),
              duration: Duration(seconds: 2),
            ),
          );

          return;
        }
      }
    }

    if (!mounted) return;
    final parsedSendAmount = double.tryParse(amountController.text);

    debugPrint("Owned asset: $asset");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ConfirmPegScreen(
              minAmount: minAmount,
              pegIn: pegIn.first,
              address:
                  (addressController.text.isEmpty)
                      ? null
                      : (addressController.text.replaceAll(",", ".")),
              sendAmount: parsedSendAmount,
              ownedAsset: asset,
              sendFromExternalWallet: receiveFromExternalWallet,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sideswapClient = ref.read(sideswapRepositoryProvider);

    return Scaffold(
      appBar: MoozeAppBar(title: "Peg-in/out"),
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SegmentedButton(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text("Peg-in"),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: false,
                  label: Text("Peg-out"),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.primary;
                  }
                  return Theme.of(context).colorScheme.secondary;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.onPrimary;
                  }
                  return Theme.of(context).colorScheme.onSecondary;
                }),
              ),
              selected: pegIn,
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  pegIn = newSelection;
                });
              },
            ),
            SizedBox(height: 24),
            PegInputDisplay(
              pegIn: pegIn.first,
              addressController: addressController,
              amountController: amountController,
              sendToExternalWallet: sendToExternalWallet,
              receiveFromExternalWallet: receiveFromExternalWallet,
            ),
            SizedBox(height: 10),
            PegAvailableFunds(pegIn: pegIn.first),
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (!pegIn.first)
                  Row(
                    children: [
                      Checkbox(
                        value: sendToExternalWallet,
                        onChanged: (value) {
                          setState(() {
                            sendToExternalWallet = value!;
                          });
                          addressController.clear();
                        },
                      ),
                      Text(
                        "Enviar peg-out para wallet externa",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text(
                                  "Enviar para uma wallet externa",
                                ),
                                content: const Text(
                                  "Caso essa opção seja selecionada, um endereço será requisitado para enviar os seus ativos. Senão, um endereço da própria carteira Mooze será utilizado. \nSelecione essa opção para enviar para uma cold wallet.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("OK"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Icon(
                          Icons.question_mark,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                if (pegIn.first)
                  Row(
                    children: [
                      Checkbox(
                        value: receiveFromExternalWallet,
                        onChanged: (value) {
                          setState(() {
                            receiveFromExternalWallet = value!;
                          });
                          amountController.clear();
                        },
                      ),
                      Text(
                        "Receber peg-in de wallet externa",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text(
                                  "Receber valores de uma wallet externa",
                                ),
                                content: const Text(
                                  """Caso essa opção seja selecionada, você poderá converter seus ativos de uma wallet externa. Senão, os valores da própria carteira Mooze serão convertidos automaticamente.
                                \nAtenção: o campo de valor se torna opcional, mas você DEVE mandar um valor maior que o valor mínimo.
                                \nSelecione essa opção para receber de uma cold wallet.""",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("OK"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Icon(
                          Icons.question_mark,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 24),
            serverStatus != null
                ? ServerStatusDisplay(
                  serverStatusFuture: serverStatus!,
                  pegIn: pegIn.first,
                )
                : CircularProgressIndicator(),
            SizedBox(height: 24),
            PrimaryButton(
              text: "Prosseguir",
              onPressed: () async => validateAndRedirect(),
            ),
          ],
        ),
      ),
    );
  }
}
