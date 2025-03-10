import 'package:lwk/lwk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_provider.g.dart';

const electrumUrl = "blockstream.info:995";

@riverpod
class LiquidNetwork extends _$LiquidNetwork {
  @override
  Network build() => Network.mainnet;
}

@Riverpod(keepAlive: true)
class LiquidWalletNotifier extends _$LiquidWalletNotifier {
  Wallet? _initializedWallet;

  @override
  AsyncValue<Wallet> build() {
    if (_initializedWallet != null) {
      return AsyncValue.data(_initializedWallet!);
    }
    return const AsyncValue.loading();
  }

  Future<void> initializeWallet(bool mainnet, String mnemonic) async {
    state = const AsyncValue.loading();
    final network = ref.watch(liquidNetworkProvider);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = '${directory.path}/lwk-db';

      final descriptor = await Descriptor.newConfidential(
        network: network,
        mnemonic: mnemonic,
      );

      final wallet = await Wallet.init(
        descriptor: descriptor,
        network: network,
        dbpath: dbPath,
      );

      // Sync wallet
      await wallet.sync(electrumUrl: electrumUrl, validateDomain: true);

      // Set wallet state
      _initializedWallet = wallet;
      state = AsyncValue.data(wallet);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Syncs the wallet with Electrum
  Future<void> sync() async {
    final wallet = state.asData?.value;
    if (wallet == null) {
      throw Exception("Carteira não inicializada.");
    }

    try {
      state = const AsyncValue.loading();
      await wallet.sync(electrumUrl: electrumUrl, validateDomain: true);
      state = AsyncValue.data(wallet);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Generates a new confidential address
  Future<String?> generateAddress() async {
    final wallet = state.asData?.value;
    if (wallet == null) {
      throw Exception("Carteira não inicializada.");
    }

    state = const AsyncValue.loading();

    final address = await wallet.addressLastUnused();

    state = AsyncValue.data(wallet);
    return address.confidential;
  }

  /// Fetches UTXOs
  Future<List<TxOut>?> getUtxos() async {
    final wallet = state.asData?.value;
    if (wallet == null) {
      throw Exception("Carteira não inicializada.");
    }

    return wallet.utxos();
  }
}
