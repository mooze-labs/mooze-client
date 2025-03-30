import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/payments.dart';
import 'package:mooze_mobile/models/user.dart';
import 'package:mooze_mobile/providers/mooze/user_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/screens/generate_pix_payment_code/generate_pix_payment_code.dart';
import 'package:mooze_mobile/screens/receive_pix/widgets/address_display.dart';
import 'package:mooze_mobile/screens/receive_pix/widgets/amount_input.dart';
import 'package:mooze_mobile/services/mooze/registration.dart';
import 'package:mooze_mobile/services/mooze/user.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/swipe_to_confirm.dart';

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
  late Future<String?> _addressFuture;
  late Future<User?> _userFuture;
  // Controller for the BRL amount input
  final TextEditingController amountController = TextEditingController();
  int _currentAmount = 0;
  User? userDetails;

  late Key dropdownKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _addressFuture =
        ref.read(liquidWalletNotifierProvider.notifier).generateAddress();

    _userFuture = _preloadUserData();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  // Handle text changes directly
  void _handleTextChanged(String text) {
    final newAmount = text.isEmpty ? 0 : int.tryParse(text) ?? 0;

    if (newAmount != _currentAmount) {
      setState(() {
        _currentAmount = newAmount;
      });
    }
  }

  void _onAssetChanged(Asset? asset) {
    if (asset == null) {
      return;
    }

    if (asset.id != "depix") {
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

  Future<User?> _preloadUserData() async {
    final userService = UserService(backendUrl: BACKEND_URL);
    final userId = await userService.getUserId();

    if (userId == null) {
      final registrationService = RegistrationService(backendUrl: BACKEND_URL);
      final newUserId = await registrationService.registerUser(null);

      if (newUserId == null) {
        debugPrint("Failed to register user");
      }

      await registrationService.saveUserId(newUserId!);
    }

    return await userService.getUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    final liquidWalletState = ref.watch(liquidWalletNotifierProvider);
    final liquidAssets = AssetCatalog.liquidAssets;

    return Scaffold(
      appBar: MoozeAppBar(title: "Receber por PIX"),
      body: liquidWalletState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, stack) =>
                Center(child: Text("Erro ao instanciar carteira: $err")),
        data:
            (_) => FutureBuilder<String?>(
              future: _addressFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Erro ao gerar endereço: ${snapshot.error}"),
                  );
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text("Nenhum endereço disponível"),
                  );
                }

                final address = snapshot.data!;

                return FutureBuilder<User?>(
                  future: _userFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      log("${snapshot.error!}");
                      return Center(
                        child: Column(
                          children: [
                            Text(
                              "Não foi possível conectar ao servidor. Tente novamente mais tarde",
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          if (liquidAssets.isNotEmpty &&
                              MediaQuery.of(context).viewInsets.bottom == 0)
                            _assetDropdown(context, liquidAssets),
                          PixInputAmount(
                            amountController: amountController,
                            onChanged: _handleTextChanged,
                          ),
                          Text("Valor mínimo: R\$ 20,00"),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: AddressDisplay(
                              address: address,
                              fiatAmount: _currentAmount,
                              asset: selectedAsset,
                            ),
                          ),
                          if (MediaQuery.of(context).viewInsets.bottom == 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 70),
                              child: SwipeToConfirm(
                                onConfirm: () {
                                  if (selectedAsset == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Por favor, selecione um ativo.",
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (_currentAmount < 20 ||
                                      _currentAmount > 5000) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Por favor, insira um valor válido.",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final pixTransaction = PixTransaction(
                                    address: address,
                                    brlAmount: _currentAmount,
                                    asset:
                                        selectedAsset.liquidAssetId ??
                                        "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189",
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              GeneratePixPaymentCodeScreen(
                                                pixTransaction: pixTransaction,
                                                assetId:
                                                    selectedAsset
                                                        .liquidAssetId!,
                                              ),
                                    ),
                                  );
                                },
                                text: "Deslize para pagar",
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                progressColor:
                                    Theme.of(context).colorScheme.secondary,
                                textColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                width: 300,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      ),
    );
  }
}
