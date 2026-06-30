import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/domain/entities/liquid_utxo.dart' as v2;
import 'package:mooze_mobile/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/key_management/store.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';

/// Routes the swap surface through the V2 [WalletRepository] (which itself
/// delegates to V2 `LiquidWalletService`). UTXO selection happens here —
/// the repo only enumerates the wallet's spendable Liquid UTXOs.
class LiquidWalletRepositoryImpl implements SwapWallet {
  LiquidWalletRepositoryImpl({
    required WalletRepository walletRepository,
    required this.mnemonicStore,
  }) : _walletRepository = walletRepository;

  final WalletRepository _walletRepository;
  final MnemonicStore mnemonicStore;

  @override
  TaskEither<String, List<SwapUtxo>> getUtxos(Asset asset, BigInt amount) {
    return TaskEither<String, List<SwapUtxo>>(() async {
      if (amount <= BigInt.zero) {
        return Either<String, List<SwapUtxo>>.right(const <SwapUtxo>[]);
      }

      final utxosResult = await _walletRepository.getLiquidUtxos();
      return utxosResult.fold<Either<String, List<SwapUtxo>>>(
        (err) => Either.left(err.toString()),
        (utxos) {
          final assetId = Asset.toId(asset);
          final filteredUtxos = utxos
              .where((u) => u.assetId == assetId)
              .toList()
            ..sort((a, b) => a.valueSat.compareTo(b.valueSat));

          final selectedUtxos = <SwapUtxo>[];
          var remaining = amount;
          for (final utxo in filteredUtxos) {
            selectedUtxos.add(_toSwapUtxo(utxo));
            remaining -= utxo.valueSat;
            if (remaining <= BigInt.zero) {
              remaining = BigInt.zero;
              break;
            }
          }

          if (remaining > BigInt.zero) {
            final missing = remaining;
            return Either.left(
              'Insufficient funds: missing $missing sats for $assetId',
            );
          }

          return Either.right(selectedUtxos);
        },
      );
    });
  }

  @override
  Task<String> getAddress() {
    return Task(() async {
      final result = await _walletRepository.getLiquidSwapAddress();
      return result.fold(
        (err) => throw Exception(err.toString()),
        (address) => address,
      );
    });
  }

  @override
  TaskEither<String, String> signSwapOperation(String pset) {
    return mnemonicStore.getMnemonic().flatMap((optionMnemonic) {
      return optionMnemonic.fold(
        () => TaskEither.left("Frase de recuperação não encontrada"),
        (mnemonic) {
          return TaskEither<String, String>(() async {
            final result = await _walletRepository.signSwapPset(
              pset: pset,
              mnemonic: mnemonic,
            );
            return result.fold<Either<String, String>>(
              (err) => Either.left(err.toString()),
              (signed) => Either.right(signed),
            );
          });
        },
      );
    });
  }

  SwapUtxo _toSwapUtxo(v2.LiquidUtxo u) {
    return SwapUtxo(
      txid: u.txid,
      vout: u.vout,
      asset: u.assetId,
      assetBf: u.assetBlindingFactor,
      value: u.valueSat,
      valueBf: u.valueBlindingFactor,
    );
  }
}
