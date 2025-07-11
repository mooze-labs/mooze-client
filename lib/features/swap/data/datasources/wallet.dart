import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lwk/lwk.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/swap/data/models/swap_utxo.dart';

const String mnemonicKey = 'mnemonic';

class LiquidWallet {
  final Wallet _wallet;
  final Network _network;
  final String _electrumUrl;
  final bool _validateDomain;

  LiquidWallet({
    required Wallet wallet,
    required Network network,
    required String electrumUrl,
    required bool validateDomain,
  }) : _wallet = wallet,
       _network = network,
       _electrumUrl = electrumUrl,
       _validateDomain = validateDomain;

  Future<void> sync() async {
    await _wallet.sync_(
      electrumUrl: _electrumUrl,
      validateDomain: _validateDomain,
    );
  }

  Future<List<SwapUtxo>> getUtxos(Asset asset, BigInt amount) async {
    final utxos = await _wallet.utxos();
    final selectedUtxos = <SwapUtxo>[];

    BigInt remainingAmount = amount;

    for (final utxo in utxos) {
      if (utxo.unblinded.asset == Asset.toId(asset)) {
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
        remainingAmount -= utxo.unblinded.value;

        // Early termination when we have enough funds
        if (remainingAmount <= BigInt.zero) {
          break;
        }
      }
    }

    return selectedUtxos;
  }

  Future<String> getAddress() async {
    final address = await _wallet.addressLastUnused();
    return address.confidential;
  }

  Future<String> signPset(String pset) async {
    final mnemonic = await FlutterSecureStorage().read(key: mnemonicKey);

    if (mnemonic == null) {
      throw Exception('Mnemonic not found');
    }

    final signedPset = await _wallet.signedPsetWithExtraDetails(
      network: _network,
      pset: pset,
      mnemonic: mnemonic,
    );

    return signedPset;
  }
}
