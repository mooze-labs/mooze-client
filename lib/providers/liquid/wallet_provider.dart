import 'package:lwk/lwk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/providers/mnemonic_provider.dart';

part 'wallet_provider.g.dart';

const electrumUrl = "blockstream.info:995";

@riverpod
class LiquidWalletNotifier extends _$LiquidWalletNotifier {
  @override
  AsyncValue<Wallet> build() {
    return const AsyncValue.loading();
  }

  Future<void> initializeWallet(Network network) async {
    state = const AsyncValue.loading();
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = '${directory.path}/lwk-db';

      // Retrieve the mnemonic (Ensure you have a provider for this)
      final mnemonic = await ref.read(mnemonicNotifierProvider.future);
      if (mnemonic == null) {
        throw Exception("Mnemônico não encontrado!");
      }

      final descriptor = await Descriptor.newConfidential(
        network: network,
        mnemonic: mnemonic,
      );

      print("Initializing Liquid wallet.");
      final wallet = await Wallet.init(
        descriptor: descriptor,
        network: network,
        dbpath: dbPath,
      );

      // Sync wallet
      print("Syncing Liquid wallet");
      await wallet.sync(electrumUrl: electrumUrl, validateDomain: true);
      print("Synced.");

      // Set wallet state
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
