import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

enum AmountDisplayMode { fiat, bitcoin, satoshis }

final amountDisplayModeProvider = StateProvider<AmountDisplayMode>((ref) {
  return AmountDisplayMode.fiat;
});

extension AmountDisplayModeExtension on AmountDisplayMode {
  AmountDisplayMode get next {
    switch (this) {
      case AmountDisplayMode.fiat:
        return AmountDisplayMode.bitcoin;
      case AmountDisplayMode.bitcoin:
        return AmountDisplayMode.satoshis;
      case AmountDisplayMode.satoshis:
        return AmountDisplayMode.fiat;
    }
  }

  String label(String currencySymbol) {
    switch (this) {
      case AmountDisplayMode.fiat:
        return currencySymbol == 'R\$' ? 'BRL' : 'USD';
      case AmountDisplayMode.bitcoin:
        return 'BTC';
      case AmountDisplayMode.satoshis:
        return 'sats';
    }
  }

  String formatAmount(
    Asset asset,
    BigInt amountInSats,
    double? assetPrice,
    String currencySymbol,
  ) {
    switch (this) {
      case AmountDisplayMode.fiat:
        if (assetPrice == null || assetPrice == 0) {
          return "$currencySymbol --";
        }
        return asset.formatAsFiat(amountInSats, assetPrice, currencySymbol);

      case AmountDisplayMode.bitcoin:
        return asset.formatAsAsset(amountInSats);

      case AmountDisplayMode.satoshis:
        return asset.formatAsSatoshis(amountInSats);
    }
  }

  BigInt parseInput(Asset asset, String input, double? assetPrice) {
    if (input.isEmpty) throw ArgumentError("Valor não pode estar vazio");

    final cleanInput = input.replaceAll(',', '.');
    final value = double.tryParse(cleanInput);

    if (value == null || value <= 0) {
      throw ArgumentError("Valor inválido");
    }

    switch (this) {
      case AmountDisplayMode.fiat:
        if (assetPrice == null || assetPrice == 0) {
          throw ArgumentError("Preço não disponível");
        }
        return asset.fromUsd(value, assetPrice);

      case AmountDisplayMode.bitcoin:
        if (asset == Asset.btc) {
          // For Bitcoin, convert BTC to satoshis
          return BigInt.from((value * 100000000).round());
        } else {
          return asset.toSatoshis(value);
        }

      case AmountDisplayMode.satoshis:
        if (asset == Asset.btc) {
          return BigInt.from(value.round());
        } else {
          return asset.toSatoshis(value);
        }
    }
  }
}
