import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/key_management/store.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';

import '../datasources/wallet.dart';

class LiquidWalletRepositoryImpl implements SwapWallet {
  final LiquidDataSource wallet;
  final MnemonicStore mnemonicStore;

  LiquidWalletRepositoryImpl({
    required this.wallet,
    required this.mnemonicStore,
  });

  @override
  TaskEither<String, List<SwapUtxo>> getUtxos(Asset asset, BigInt amount) {
    return TaskEither<String, List<SwapUtxo>>(() async {
      final utxos = await wallet.wallet.utxos();
      final filteredUtxos = utxos.where((u) => u.unblinded.asset == Asset.toId(asset)).toList();
      
      final selectedUtxos = <SwapUtxo>[];
      var remaining = amount;
      
      for (final utxo in filteredUtxos) {
        if (remaining <= BigInt.zero) break;
        
        selectedUtxos.add(SwapUtxo(
          txid: utxo.outpoint.txid,
          vout: utxo.outpoint.vout,
          asset: utxo.unblinded.asset,
          assetBf: utxo.unblinded.assetBf,
          value: utxo.unblinded.value,
          valueBf: utxo.unblinded.valueBf,
        ));
        
        remaining -= utxo.unblinded.value;
      }
      
      final result = (utxos: selectedUtxos, remaining: remaining);

      if (result.remaining > BigInt.zero) {
        return Either<String, List<SwapUtxo>>.left("Insufficient funds");
      }

      return Either<String, List<SwapUtxo>>.right(result.utxos);
    });
  }

  @override
  Task<String> getAddress() {
    return Task(
      () async => await wallet.wallet.addressLastUnused().then(
        (address) => address.confidential,
      ),
    );
  }

  @override
  TaskEither<String, String> signSwapOperation(String pset) {
    return mnemonicStore.getMnemonic().flatMap((optionMnemonic) {
      return optionMnemonic.fold(
        () => TaskEither.left("Frase de recuperação não encontrada"),
        (mnemonic) {
          return TaskEither.tryCatch(
            () async => await wallet.wallet.signedPsetWithExtraDetails(
              network: wallet.network,
              pset: pset,
              mnemonic: mnemonic,
            ),
            (error, stackTrace) => error.toString(),
          );
        },
      );
    });
  }
}
