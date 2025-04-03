import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/transaction.dart';
import 'package:mooze_mobile/repositories/wallet/bitcoin.dart';
import 'package:mooze_mobile/repositories/wallet/repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bitcoin_provider.g.dart';

const electrumUrl = "blockstream.info";

@Riverpod(keepAlive: true)
WalletRepository bitcoinWalletRepository(Ref ref) {
  return BitcoinWalletRepository();
}

@Riverpod(keepAlive: true)
class BitcoinWalletNotifier extends _$BitcoinWalletNotifier {
  late WalletRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.read(bitcoinWalletRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<void> initializeWallet(bool mainnet, String mnemonic) async {
    state = const AsyncValue.loading();

    try {
      await _repository.initializeWallet(mainnet, mnemonic);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> sync() async {
    state = const AsyncValue.loading();
    try {
      await _repository.sync();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<String?> generateAddress() async {
    try {
      return await _repository.generateAddress();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  Future<List<OwnedAsset>> getOwnedAssets() async {
    try {
      return await _repository.getOwnedAssets();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return [OwnedAsset.bitcoin(0)];
    }
  }

  Future<PartiallySignedTransaction> buildTransaction({
    required OwnedAsset asset,
    required String recipient,
    required int amount,
    required double feeRate,
  }) async {
    try {
      final pset = await _repository.buildPartiallySignedTransaction(
        asset,
        recipient,
        amount,
        feeRate,
      );
      return pset;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow; // Allow caller to handle the error
    }
  }

  Future<Transaction> signAndBroadcastTransaction(
    PartiallySignedTransaction pst,
  ) async {
    try {
      return await _repository.signTransaction(pst);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<List<TransactionRecord>> getTransactionHistory() async {
    try {
      return await _repository.getTransactionHistory();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}
