const lbtcAssetId =
    '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';
const usdtAssetId =
    'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2';
const depixAssetId =
    '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189';

// Unified bitcoin values - no distinction between BTC and LBTC
enum Asset {
  btc,
  lbtc,
  depix,
  usdt;

  static Asset fromId(String id) {
    return switch (id) {
      usdtAssetId => Asset.usdt,
      depixAssetId => Asset.depix,
      lbtcAssetId => Asset.lbtc,
      _ => Asset.btc,
    };
  }

  static String? toId(Asset asset) {
    return switch (asset) {
      Asset.usdt => usdtAssetId,
      Asset.depix => depixAssetId,
      Asset.lbtc => lbtcAssetId,
      _ => null,
    };
  }

  String get ticker {
    return switch (this) {
      Asset.usdt => "USDT",
      Asset.depix => "Depix",
      Asset.lbtc => "LBTC",
      Asset.btc => "BTC",
    };
  }

  String get name {
    return switch (this) {
      Asset.usdt => "USDt",
      Asset.depix => "Decentralized Pix",
      Asset.lbtc => "Liquid Bitcoin",
      Asset.btc => "bitcoin",
    };
  }

  String get id {
    return switch (this) {
      Asset.usdt => usdtAssetId,
      Asset.depix => depixAssetId,
      Asset.btc => lbtcAssetId,
      Asset.lbtc => lbtcAssetId,
    };
  }

  String get iconPath {
    return switch (this) {
      Asset.usdt => 'assets/new_ui_wallet/assets/icons/asset/usdt.svg',
      Asset.depix => 'assets/new_ui_wallet/assets/icons/asset/depix.svg',
      Asset.btc => 'assets/new_ui_wallet/assets/icons/asset/bitcoin.svg',
      Asset.lbtc =>
        'assets/new_ui_wallet/assets/icons/asset/layer2_bitcoin.svg',
    };
  }

  /// Formats asset balance according to its specific rules
  String formatBalance(BigInt balanceInSats) {
    return switch (this) {
      Asset.btc => _formatBitcoinBalance(balanceInSats),
      Asset.lbtc => _formatBitcoinBalance(balanceInSats),
      Asset.usdt => _formatTokenBalance(balanceInSats, "USDT"),
      Asset.depix => _formatTokenBalance(balanceInSats, "DEPIX"),
    };
  }

  /// Converts satoshis to asset's natural unit
  double fromSatoshis(BigInt satoshis) {
    return switch (this) {
      Asset.btc => satoshis.toDouble(), // Bitcoin remains in satoshis
      Asset.lbtc => satoshis.toDouble(),
      Asset.usdt ||
      Asset.depix => satoshis.toDouble() / 100000000, // Tokens divide by 100M
    };
  }

  /// Converts asset's natural unit to satoshis
  BigInt toSatoshis(double amount) {
    return switch (this) {
      Asset.btc || Asset.lbtc => BigInt.from(
        (amount * 100000000).round(),
      ), // Bitcoin: BTC -> sats
      Asset.usdt || Asset.depix => BigInt.from(
        (amount * 100000000).round(),
      ), // Tokens multiply by 100M
    };
  }

  /// Converts satoshis from this asset to another asset using USD prices
  BigInt convertToAsset(
    BigInt amountInSats,
    Asset targetAsset,
    double fromPriceUsd,
    double toPriceUsd,
  ) {
    if (this == targetAsset) return amountInSats;

    // Convert to USD value
    final double fromAmount = fromSatoshis(amountInSats);
    final double usdValue = fromAmount * fromPriceUsd;

    // Convert USD to target asset
    final double targetAmount = usdValue / toPriceUsd;

    return targetAsset.toSatoshis(targetAmount);
  }

  /// Converts asset value to USD
  double toUsd(BigInt amountInSats, double priceUsd) {
    if (this == Asset.btc) {
      // For Bitcoin: convert satoshis to BTC then to USD
      final double btcAmount = amountInSats.toDouble() / 100000000;
      return btcAmount * priceUsd;
    } else {
      // For other assets: use fromSatoshis directly
      final double amount = fromSatoshis(amountInSats);
      return amount * priceUsd;
    }
  }

  /// Converts USD value to asset
  BigInt fromUsd(double usdAmount, double priceUsd) {
    final double amount = usdAmount / priceUsd;
    return toSatoshis(amount);
  }

  String formatAsFiat(
    BigInt amountInSats,
    double priceUsd,
    String currencySymbol,
  ) {
    final usdValue = toUsd(amountInSats, priceUsd);
    return "$currencySymbol ${usdValue.toStringAsFixed(2)}";
  }

  String formatAsAsset(BigInt amountInSats) {
    if (this == Asset.btc) {
      final btcAmount = fromSatoshis(amountInSats) / 100000000;
      return "${btcAmount.toStringAsFixed(8)} BTC";
    } else {
      final amount = fromSatoshis(amountInSats);
      return "${amount.toStringAsFixed(8)} $ticker";
    }
  }

  /// Formats value in satoshis (Bitcoin only)
  String formatAsSatoshis(BigInt amountInSats) {
    if (this == Asset.btc) {
      final sats = amountInSats.toInt();
      final satText = sats == 1 ? 'sat' : 'sats';
      return "$sats $satText";
    } else {
      return formatAsAsset(amountInSats);
    }
  }

  /// Formats Bitcoin balance in SATs
  static String _formatBitcoinBalance(BigInt balanceInSats) {
    if (balanceInSats == BigInt.zero) {
      return "0 SATS";
    }

    if (balanceInSats == BigInt.one) {
      return "1 SAT";
    }

    return "${balanceInSats.toString()} SATS";
  }

  /// Formats token balance (USDT/DEPIX) converting from satoshis to whole units
  static String _formatTokenBalance(BigInt balanceInSats, String ticker) {
    if (balanceInSats == BigInt.zero) {
      return "0 $ticker";
    }

    // Convert from satoshis to whole units (divide by 100,000,000)
    final BigInt satoshisPerUnit = BigInt.from(100000000);
    final BigInt wholePart = balanceInSats ~/ satoshisPerUnit;
    final BigInt remainder = balanceInSats % satoshisPerUnit;

    if (remainder == BigInt.zero) {
      // Whole value
      return "${wholePart.toString()} $ticker";
    } else {
      // Decimal value - show up to 8 decimal places and remove trailing zeros
      final double value =
          balanceInSats.toDouble() / satoshisPerUnit.toDouble();
      final String formatted = value
          .toStringAsFixed(8)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
      return "$formatted $ticker";
    }
  }
}
