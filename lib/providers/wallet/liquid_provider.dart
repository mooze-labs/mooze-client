import 'package:flutter/foundation.dart';
import 'package:lwk/lwk.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/transaction.dart';
import 'package:mooze_mobile/repositories/wallet/liquid.dart';
import 'package:mooze_mobile/repositories/wallet/repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'liquid_provider.g.dart';

const electrumUrl = "blockstream.info:995";

@Riverpod(keepAlive: true)
WalletRepository liquidWalletRepository(Ref ref) {
  return LiquidWalletRepository();
}

@Riverpod(keepAlive: true)
class LiquidWalletNotifier extends _$LiquidWalletNotifier {
  late WalletRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.read(liquidWalletRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<void> initializeWallet(bool mainnet, String mnemonic) async {
    state = const AsyncValue.loading();
    try {
      await _repository.initializeWallet(mainnet, mnemonic);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      debugPrint("Failed to initialize Liquid wallet: $e");
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
      debugPrint("Error fetching owned assets: $e");
      state = AsyncValue.error(e, StackTrace.current);
      return []; // Fallback
    }
  }

  Future<PartiallySignedTransaction> buildTransaction({
    required OwnedAsset asset,
    required String recipient,
    required int amount,
    required double feeRate,
  }) async {
    try {
      return await _repository.buildPartiallySignedTransaction(
        asset,
        recipient,
        amount,
        feeRate,
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
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

  Future<List<TxOut>> fetchUtxos() async {
    try {
      return await (_repository as LiquidWalletRepository).fetchUtxos();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return []; // Fallback
    }
  }

  Future<String> signPsetWithExtraDetails(String pset) async {
    try {
      return await (_repository as LiquidWalletRepository)
          .signPsetWithExtraDetails(pset);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}
