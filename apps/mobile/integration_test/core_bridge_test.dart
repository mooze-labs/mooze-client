import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';
import 'package:path_provider/path_provider.dart';

/// Runs the Rust core inside the real app on a device or simulator.
///
/// It opens the core, connects the well-known test mnemonic over the
/// default Electrum servers and syncs both chains. The mnemonic has public
/// mainnet history, so a working sync finds transactions. Needs network.
///
/// Run: flutter test integration_test/core_bridge_test.dart -d <device id>
const _abandon =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('core opens, connects and syncs over Electrum on device',
      (tester) async {
    await MoozeCoreLib.init();
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/core-it-${DateTime.now().millisecondsSinceEpoch}');
    await dir.create(recursive: true);

    final core = await MoozeCore.open(
      config: CoreConfig(
        dataDir: dir.path,
        network: NetworkDto.mainnet,
        backend: BackendDto.electrum,
        bitcoinNodeUrl: '',
        liquidNodeUrl: '',
      ),
    );

    await core.bitcoinConnect(mnemonic: _abandon);
    final btcAddress = await core.bitcoinReceiveAddress();
    expect(btcAddress.address, 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu');
    final btcSync = await core.bitcoinSync().timeout(const Duration(minutes: 5));
    final btcTxs = await core.bitcoinTransactions();
    // ignore: avoid_print
    print('bitcoin sync: fetched=${btcSync.fetched} txs=${btcTxs.length}');
    expect(btcTxs, isNotEmpty);

    await core.liquidConnect(mnemonic: _abandon);
    final lqSync = await core.liquidSync().timeout(const Duration(minutes: 5));
    final lqTxs = await core.liquidTransactions();
    final lqBalance = await core.liquidBalance();
    // ignore: avoid_print
    print('liquid sync: fetched=${lqSync.fetched} txs=${lqTxs.length} '
        'assets=${lqBalance.assets.length}');
    expect(lqTxs, isNotEmpty);

    await dir.delete(recursive: true);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
