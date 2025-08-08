import 'dart:io';

import 'package:lwk/lwk.dart' as liquid;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/screens/wallet/widgets/balance_display.dart';
import 'package:mooze_mobile/screens/wallet/widgets/wallet_buttons.dart';
import 'package:mooze_mobile/services/mooze/update.dart';
import 'package:mooze_mobile/widgets/buttons.dart';
import 'package:mooze_mobile/widgets/mooze_drawer.dart';
import 'package:mooze_mobile/screens/wallet/widgets/coin_balance.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkUpdate();
    });
  }

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  Future<List<liquid.Balance>> getLiquidAssetBalances(
    liquid.Wallet wallet,
  ) async {
    final balances = await wallet.balances();
    return balances;
  }

  Future<void> checkUpdate() async {
    if (!mounted) return;
    
    try {
      final currentAppVersion = await UpdateService().getUpdateData().then((f) => f.currentVersion);
      if (kDebugMode) {
        debugPrint("Current app version: $currentAppVersion");
        debugPrint("Local version: $currentVersion");
      }

      if (currentAppVersion != currentVersion && mounted) {
        showDialog(context: context, builder: (context) => AlertDialog(
          title: Text("Atualização disponível"), 
          content: Text("Uma atualização está disponível para download. Ao clicar em Download, você será redirecionado ao site para baixar a nova atualização."),
          actions: [
            TextButton(
                onPressed: () {
                  if (Platform.isIOS) {
                    launchUrlString(
                        "https://testflight.apple.com/join/BmxNjKb1",
                        mode: LaunchMode.externalApplication);
                  } else {
                    launchUrlString("https://mooze.app", mode: LaunchMode.externalApplication);
                  }
                  Navigator.pop(context);
                },
                child: Text("Download"),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Ignorar"))
          ],
        ));
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Failed to get update status. $e");
      return;
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: Text(
        "Carteira",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: "roboto",
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: _toggleBalanceVisibility,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownedAssetsState = ref.watch(ownedAssetsNotifierProvider.future);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: _buildAppBar(context),
        drawer: MoozeDrawer(),
        body: FutureBuilder<List<OwnedAsset>>(
          future: ownedAssetsState,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final ownedAssets = snapshot.data!;
            return Center(
              child: Column(
                children: [
                  BalanceDisplay(isBalanceVisible: _isBalanceVisible),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      WalletButtonBox(
                        label: "Enviar",
                        icon: Icons.arrow_outward,
                        onTap:
                            () => Navigator.pushNamed(context, "/send_funds"),
                      ),
                      WalletButtonBox(
                        label: "Receber",
                        icon: Icons.call_received,
                        onTap:
                            () =>
                                Navigator.pushNamed(context, "/receive_funds"),
                      ),
                      WalletButtonBox(
                        label: "Swap",
                        icon: Icons.swap_horiz,
                        onTap: () => Navigator.pushNamed(context, "/swap"),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Ativos",
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 5),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(ownedAssetsNotifierProvider.notifier)
                            .refresh();
                        return ref.refresh(ownedAssetsNotifierProvider.future);
                      },
                      child: ListView.builder(
                        itemCount: ownedAssets.length,
                        itemBuilder:
                            (context, index) => CoinBalance(
                              ownedAsset: ownedAssets[index],
                              isBalanceVisible: _isBalanceVisible,
                            ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 40.0),
                    child: PrimaryButton(
                      text: "Receber PIX",
                      onPressed:
                          () => Navigator.pushNamed(context, "/receive_pix"),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
