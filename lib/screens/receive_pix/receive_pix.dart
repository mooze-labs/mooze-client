import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/payments.dart';
import 'package:mooze_mobile/models/user.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import 'package:mooze_mobile/providers/mooze/user_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/screens/receive_pix/generate_pix_payment_code.dart';
import 'package:mooze_mobile/screens/receive_pix/widgets/address_display.dart';
import 'package:mooze_mobile/screens/receive_pix/widgets/amount_input.dart';
import 'package:mooze_mobile/services/mooze/registration.dart';
import 'package:mooze_mobile/services/mooze/user.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/swipe_to_confirm.dart';
import 'package:shared_preferences/shared_preferences.dart';

const BACKEND_URL = String.fromEnvironment(
  "BACKEND_URL",
  defaultValue: "api.mooze.app",
);

class ReceivePixScreen extends ConsumerStatefulWidget {
  const ReceivePixScreen({Key? key}) : super(key: key);

  @override
  ReceivePixState createState() => ReceivePixState();
}

class ReceivePixState extends ConsumerState<ReceivePixScreen> {
  // depix as default asset
  Asset selectedAsset = AssetCatalog.getById("depix")!;
  String? _address;
  User? _userDetails;
  DateTime? _userDetailsFetchedAt;
  bool _isLoading = true;
  String? _error;
  bool _hasReferral = false;

  // Controller for the BRL amount input
  final TextEditingController amountController = TextEditingController();

  double _currentAmountFloat = 0.0;
  int _currentAmountInCents = 0;
  bool _isValidating = false;

  late Key dropdownKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // Add listener to handle text changes
    amountController.addListener(() {
      final text = amountController.text;
      final normalizedText = text.replaceAll(',', '.');
      final newAmount =
          normalizedText.isNotEmpty
              ? double.tryParse(normalizedText) ?? 0.0
              : 0.0;

      if (newAmount != _currentAmountFloat) {
        setState(() {
          _currentAmountFloat = newAmount;
          _currentAmountInCents = (newAmount * 100).round();
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final address =
          await ref
              .read(liquidWalletNotifierProvider.notifier)
              .generateAddress();
      final userService = UserService(backendUrl: BACKEND_URL);
      final userDetails = await userService.getUserDetails();
      final sharedPreferences = await SharedPreferences.getInstance();
      final hasReferral = sharedPreferences.getString('referralCode') != null;

      if (mounted) {
        setState(() {
          _address = address;
          _userDetails = userDetails;
          _userDetailsFetchedAt = DateTime.now();
          _hasReferral = hasReferral;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void _onAssetChanged(Asset? asset) {
    if (asset == null) {
      return;
    }

    if (asset.id != "depix" && asset.id != "lbtc") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Em breve.")));

      setState(() {
        selectedAsset = AssetCatalog.getById("depix")!;
        dropdownKey = UniqueKey();
      });
    } else {
      setState(() {
        selectedAsset = asset;
      });
    }
  }

  Future<bool> validateUserInput(int amount) async {
    if (_isValidating) return false;
    _isValidating = true;

    try {
      // Only fetch user details if they're missing or we need to refresh them
      if (_userDetails == null || _shouldRefreshUserDetails()) {
        final userService = ref.read(userServiceProvider);
        _userDetails = await userService.getUserDetails();
        // Update the timestamp when we fetch fresh data
        _userDetailsFetchedAt = DateTime.now();
      }

      if (!mounted) return false;

      if (_userDetails == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Não foi possível conectar ao servidor."),
          ),
        );
        return false;
      }

      if (amount > _userDetails!.allowedSpending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Limite de transação excedido.")),
        );
        return false;
      }

      if (amount < 20 * 100 || amount > 5000 * 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Por favor, insira um valor entre R\$ 20,00 e R\$ 5.000,00.",
            ),
          ),
        );
        return false;
      }

      return true;
    } finally {
      _isValidating = false;
    }
  }

  // Helper to determine when user details should be refreshed
  bool _shouldRefreshUserDetails() {
    // Refresh if details are older than 5 minutes
    if (_userDetailsFetchedAt == null) {
      return true;
    }

    final difference = DateTime.now().difference(_userDetailsFetchedAt!);
    return difference.inMinutes > 5;
  }

  Widget _assetDropdown(BuildContext context, List<Asset> assets) {
    return DropdownMenu<Asset>(
      key: dropdownKey,
      initialSelection: assets.firstWhere(
        (asset) => asset.id == selectedAsset.id,
        orElse: () => assets[0],
      ),
      textAlign: TextAlign.center,
      leadingIcon: Transform.scale(
        scale: 0.5,
        child: Image.asset(selectedAsset.logoPath, width: 8, height: 8),
      ),
      onSelected: _onAssetChanged,
      dropdownMenuEntries:
          assets.map((Asset asset) {
            return DropdownMenuEntry<Asset>(
              value: asset,
              label: asset.name,
              leadingIcon: Image.asset(asset.logoPath, width: 24, height: 24),
            );
          }).toList(),
      label: const Text("Selecione um ativo"),
      inputDecorationTheme:
          Theme.of(context).dropdownMenuTheme.inputDecorationTheme,
      menuStyle: Theme.of(context).dropdownMenuTheme.menuStyle,
    );
  }

  Widget _buildAmountDependentWidgets() {
    final fiatPrice = ref
        .watch(fiatPricesProvider)
        .when(
          loading: () => 0.0,
          error: (err, stack) {
            print("[ERROR] Error fetching price: $err");
            return 0.0;
          },
          data: (fiatPrices) {
            if (selectedAsset.fiatPriceId == null) return 0.0;
            if (!fiatPrices.containsKey(selectedAsset.fiatPriceId)) return 0.0;
            return fiatPrices[selectedAsset.fiatPriceId!]!;
          },
        );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AddressDisplay(
            address: _address!,
            fiatAmount: _currentAmountInCents,
            asset: selectedAsset,
            hasReferral: _hasReferral,
            fiatPrice: fiatPrice,
          ),
        ),
        if (MediaQuery.of(context).viewInsets.bottom == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 70),
            child: SwipeToConfirm(
              onConfirm: () async {
                final result = await validateUserInput(_currentAmountInCents);

                if (!result) return;

                final pixTransaction = PixTransaction(
                  address: _address!,
                  brlAmount: _currentAmountInCents,
                  asset:
                      selectedAsset.liquidAssetId ??
                      "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189",
                );

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => GeneratePixPaymentCodeScreen(
                            pixTransaction: pixTransaction,
                            assetId: selectedAsset.liquidAssetId!,
                          ),
                    ),
                  );
                }
              },
              text: "Deslize para pagar",
              backgroundColor: Theme.of(context).colorScheme.primary,
              progressColor: Theme.of(context).colorScheme.secondary,
              textColor: Theme.of(context).colorScheme.onPrimary,
              width: 300,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final liquidAssets = AssetCatalog.liquidAssets;

    if (_isLoading) {
      return Scaffold(
        appBar: MoozeAppBar(title: "Comprar com PIX"),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: MoozeAppBar(title: "Comprar com PIX"),
        body: Center(child: Text("Erro: $_error")),
      );
    }

    if (_address == null || _userDetails == null) {
      return Scaffold(
        appBar: MoozeAppBar(title: "Comprar com PIX"),
        body: const Center(child: Text("Nenhum endereço disponível")),
      );
    }

    return Scaffold(
      appBar: MoozeAppBar(title: "Comprar com PIX"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            if (liquidAssets.isNotEmpty &&
                MediaQuery.of(context).viewInsets.bottom == 0)
              _assetDropdown(context, liquidAssets),
            PixInputAmount(
              amountController: amountController,
              userDetails: _userDetails,
              onChanged:
                  (
                    text,
                  ) {}, // Empty callback since we're using the controller's listener
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "• Valor mínimo: R\$ 20,00 \n• Limite diário por CPF/CNPJ: R\$ 5.000,00",
                  style: TextStyle(fontFamily: "roboto", fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text("Limite diário"),
                            scrollable: true,
                            content: Text("""
O limite de pagamento via PIX na Mooze é compartilhado com outras plataformas que utilizam o sistema DEPIX, incluindo compras P2P ou concorrentes. Esse limite é monitorado pelas processadoras de pagamento por meio do sistema PIX do BACEN, com base no CPF ou CNPJ vinculado ao DEPIX. Assim, ao atingir o teto diário de R\$5.000 em transações realizadas fora da Mooze, novas tentativas de pagamento via nossos QR Codes serão automaticamente bloqueadas e estornadas à conta de origem.
Essa limitação protege o usuário contra a obrigatoriedade de reporte automático de transações. Nem a Mooze nem as processadoras realizam comunicação compulsória dessas operações, preservando a sua privacidade.
                        """),
                          ),
                    );
                  },
                  child: Icon(
                    Icons.question_mark,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            _buildAmountDependentWidgets(),
          ],
        ),
      ),
    );
  }
}
