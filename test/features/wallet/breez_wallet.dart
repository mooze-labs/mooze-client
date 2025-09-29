import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/breez.dart';

void main() {
  group("Wallet operations", () {
    test("Wallet instantiation", () async {
      await initialize();
      final mnemonic = String.fromEnvironment(
        "MNEMONIC",
        defaultValue: "all all all all all all all all all all all all",
      );
      final Config config = defaultConfig(
        network: LiquidNetwork.testnet,
        breezApiKey: String.fromEnvironment("BREEZ_API_KEY"),
      );

      final ConnectRequest connReq = ConnectRequest(
        config: config,
        mnemonic: mnemonic,
      );

      final breezSdk = await connect(req: connReq);
      final BreezWalletRepositoryImpl walletRepo = BreezWalletRepositoryImpl(
        breezSdk,
      );

      final balance = await walletRepo.getBalance();
      print(balance);
    });
  });
}
