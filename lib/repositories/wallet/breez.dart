import 'dart:async';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:lwk/lwk.dart' show lBtcAssetId, lTestAssetId;
import 'package:mooze_mobile/repositories/wallet/mnemonic.dart';
import 'package:mooze_mobile/repositories/wallet/node_config.dart'
    as node_config;

const String breezApiKey = "breez-api-key";

class BreezRepository {
  final node_config.NodeConfigRepository _nodeConfigRepository;
  final MnemonicRepository _mnemonicRepository;

  BindingLiquidSdk? _client;
  StreamSubscription<SdkEvent>? _breezEventSubscription;
  Stream<SdkEvent>? _breezEventStream;

  BreezRepository(
    this._client,
    this._nodeConfigRepository,
    this._mnemonicRepository,
  );

  BindingLiquidSdk? get client => _client;
  Stream<SdkEvent>? get eventStream => _breezEventStream;

  Future<void> initialize() async {
    final network =
        (_nodeConfigRepository.network == node_config.Network.mainnet)
            ? LiquidNetwork.mainnet
            : LiquidNetwork.testnet;

    final config = defaultConfig(
      network: network,
      breezApiKey: _nodeConfigRepository.breezApiKey,
    );

    ConnectRequest connectRequest = ConnectRequest(
      mnemonic: _mnemonicRepository.mnemonic,
      config: config,
    );

    _client = await connect(req: connectRequest);
  }

  void _initializeEventStream() {
    _breezEventStream ??= _client?.addEventListener().asBroadcastStream();
  }

  Future<Map<String, BigInt>> getBalance() async {
    final GetInfoResponse? info = await _client?.getInfo();
    if (info == null) {
      throw Exception("Failed to get balance.");
    }

    final policyAsset =
        _nodeConfigRepository.network == node_config.Network.mainnet
            ? lBtcAssetId
            : lTestAssetId;

    BigInt balanceSat = info.walletInfo.balanceSat;
    List<AssetBalance> assetBalances = info.walletInfo.assetBalances;

    Map<String, BigInt> balance = {};

    balance[policyAsset] = balanceSat;
    for (AssetBalance assetBalance in assetBalances) {
      balance[assetBalance.assetId] = assetBalance.balanceSat;
    }

    return balance;
  }

  Future<void> disconnect() async {
    await _client?.disconnect();
  }
}
