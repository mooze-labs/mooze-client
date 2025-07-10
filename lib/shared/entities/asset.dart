import 'package:uuid/uuid.dart';

const lbtcAssetId =
    '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';
const usdtAssetId =
    'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2';
const depixAssetId =
    '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189';

// As we are implementing unified bitcoin values, no distinction between btc and lbtc will be made.
enum Asset {
  btc,
  depix,
  usdt;

  static Asset fromId(String id) {
    return switch (id) {
      usdtAssetId => Asset.usdt,
      depixAssetId => Asset.depix,
      lbtcAssetId => Asset.btc,
      _ => Asset.btc,
    };
  }

  static String toId(Asset asset) {
    return switch (asset) {
      Asset.usdt => usdtAssetId,
      Asset.depix => depixAssetId,
      Asset.btc => lbtcAssetId,
    };
  }

  String get ticker {
    return switch (this) {
      Asset.usdt => "USDT",
      Asset.depix => "Depix",
      Asset.btc => "BTC",
    };
  }

  String get name {
    return switch (this) {
      Asset.usdt => "USDt",
      Asset.depix => "Decentralized Pix",
      Asset.btc => "Bitcoin",
    };
  }
}
