import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/key_management/store.dart';
import 'package:mooze_mobile/shared/infra/lwk/wallet.dart';
import 'package:mooze_mobile/shared/infra/lwk/sync/sync_controller.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';

class LiquidWalletRepositoryImpl implements SwapWallet {
  final LiquidDataSource wallet;
  final MnemonicStore mnemonicStore;
  final WalletSyncController? syncController;

  LiquidWalletRepositoryImpl({
    required this.wallet,
    required this.mnemonicStore,
    this.syncController,
  });

  @override
  TaskEither<String, List<SwapUtxo>> getUtxos(Asset asset, BigInt amount) {
    return TaskEither<String, List<SwapUtxo>>(() async {
      if (amount <= BigInt.zero) {
        return Either<String, List<SwapUtxo>>.right(const <SwapUtxo>[]);
      }

      // guarantee sync completed or trigger if needed
      if (syncController != null) {
        await syncController!.ensureSynced();
      }

      final utxos = await wallet.wallet.utxos();

      final filteredUtxos =
          utxos.where((u) => u.unblinded.asset == Asset.toId(asset)).toList();
      filteredUtxos.sort(
        (a, b) => a.unblinded.value.compareTo(b.unblinded.value),
      );

      final selectedUtxos = <SwapUtxo>[];
      var remaining = amount;
      for (final utxo in filteredUtxos) {
        selectedUtxos.add(
          SwapUtxo(
            txid: utxo.outpoint.txid,
            vout: utxo.outpoint.vout,
            asset: utxo.unblinded.asset,
            assetBf: utxo.unblinded.assetBf,
            value: utxo.unblinded.value,
            valueBf: utxo.unblinded.valueBf,
          ),
        );
        remaining -= utxo.unblinded.value;
        if (remaining <= BigInt.zero) {
          remaining = BigInt.zero;
          break;
        }
      }

      if (remaining > BigInt.zero) {
        final missing = remaining;
        return Either<String, List<SwapUtxo>>.left(
          'Insufficient funds: missing $missing sats for ${Asset.toId(asset)}',
        );
      }

      return Either<String, List<SwapUtxo>>.right(selectedUtxos);
    });
  }

  @override
  Task<String> getAddress() {
    return Task(() async {
      if (syncController != null) {
        await syncController!.ensureSynced();
      }
      return await wallet.wallet.addressLastUnused().then(
        (address) => address.confidential,
      );
    });
  }

  @override
  TaskEither<String, String> signSwapOperation(String pset) {
    return mnemonicStore.getMnemonic().flatMap((optionMnemonic) {
      return optionMnemonic.fold(
        () => TaskEither.left("Frase de recuperação não encontrada"),
        (mnemonic) {
          return TaskEither.tryCatch(() async {
            if (syncController != null) {
              await syncController!.ensureSynced();
            }
            return await wallet.wallet.signedPsetWithExtraDetails(
              network: wallet.network,
              pset: pset,
              mnemonic: mnemonic,
            );
          }, (error, stackTrace) => error.toString());
        },
      );
    });
  }
}
