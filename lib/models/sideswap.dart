import 'package:mooze_mobile/models/assets.dart';

/// Direction for swap operations
enum SwapDirection { buy, sell }

/// Status of a transaction
enum TxState { insufficientAmount, detected, processing, done, unknown }

enum AssetType { base, quote }

/// Represents a market on the Sideswap platform
class SideswapMarket {
  final String baseAssetId;
  final String quoteAssetId;
  final String feeAsset; // "Base" or "Quote"
  final String type; // "Stablecoin", "Amp", "Token"

  SideswapMarket({
    required this.baseAssetId,
    required this.quoteAssetId,
    required this.feeAsset,
    required this.type,
  });

  factory SideswapMarket.fromJson(Map<String, dynamic> json) {
    final assetPair = json['asset_pair'];
    return SideswapMarket(
      baseAssetId: assetPair['base'],
      quoteAssetId: assetPair['quote'],
      feeAsset: json['fee_asset'],
      type: json['type'],
    );
  }
}

/// A successful quote from the Sideswap API
class SideswapQuote {
  final int quoteId;
  final int baseAmount;
  final int quoteAmount;
  final int serverFee;
  final int fixedFee;
  final int ttl;

  SideswapQuote({
    required this.quoteId,
    required this.baseAmount,
    required this.quoteAmount,
    required this.serverFee,
    required this.fixedFee,
    required this.ttl,
  });

  factory SideswapQuote.fromJson(Map<String, dynamic> json) {
    final success = json['status']['Success'];
    return SideswapQuote(
      quoteId: success['quote_id'],
      baseAmount: success['base_amount'],
      quoteAmount: success['quote_amount'],
      serverFee: success['server_fee'],
      fixedFee: success['fixed_fee'],
      ttl: success['ttl'],
    );
  }
}

/// Error result for a quote attempt
class QuoteError {
  final String errorMessage;

  QuoteError({required this.errorMessage});

  factory QuoteError.fromJson(Map<String, dynamic> json) {
    return QuoteError(errorMessage: json['status']['Error']['error_msg']);
  }
}

/// Low balance result for a quote attempt
class QuoteLowBalance {
  final int available;
  final int baseAmount;
  final int quoteAmount;
  final int serverFee;
  final int fixedFee;

  QuoteLowBalance({
    required this.available,
    required this.baseAmount,
    required this.quoteAmount,
    required this.serverFee,
    required this.fixedFee,
  });

  factory QuoteLowBalance.fromJson(Map<String, dynamic> json) {
    final lowBalance = json['status']['LowBalance'];
    return QuoteLowBalance(
      available: lowBalance['available'],
      baseAmount: lowBalance['base_amount'],
      quoteAmount: lowBalance['quote_amount'],
      serverFee: lowBalance['server_fee'],
      fixedFee: lowBalance['fixed_fee'],
    );
  }
}

/// Represents a quote response which could be a success, error, or low balance
class QuoteResponse {
  final SideswapQuote? quote;
  final QuoteError? error;
  final QuoteLowBalance? lowBalance;

  QuoteResponse({this.quote, this.error, this.lowBalance});

  factory QuoteResponse.fromJson(Map<String, dynamic> json) {
    if (json['status'].containsKey('Success')) {
      return QuoteResponse(quote: SideswapQuote.fromJson(json));
    } else if (json['status'].containsKey('Error')) {
      return QuoteResponse(error: QuoteError.fromJson(json));
    } else if (json['status'].containsKey('LowBalance')) {
      return QuoteResponse(lowBalance: QuoteLowBalance.fromJson(json));
    } else {
      return QuoteResponse(
        error: QuoteError(errorMessage: "Unknown quote response"),
      );
    }
  }

  bool get isSuccess => quote != null;
  bool get isError => error != null;
  bool get isLowBalance => lowBalance != null;
}

/// UTXO used in swap transactions
class SwapUtxo {
  final String txid;
  final int vout;
  final String asset;
  final String assetBf; // asset blinding factor
  final int value;
  final String valueBf; // value blinding factor
  final String? redeemScript;

  SwapUtxo({
    required this.txid,
    required this.vout,
    required this.asset,
    required this.assetBf,
    required this.value,
    required this.valueBf,
    this.redeemScript,
  });

  Map<String, dynamic> toJson() {
    return {
      'txid': txid,
      'vout': vout,
      'asset': asset,
      'asset_bf': assetBf,
      'value': value,
      'value_bf': valueBf,
      'redeem_script': redeemScript,
    };
  }
}

/// Transaction in a peg order
class PegTransaction {
  final String txHash;
  final int vout;
  final String status;
  final int amount;
  final int? payout;
  final String? payoutTxid;
  final DateTime createdAt;
  final TxState txState;
  final int txStateCode;
  final int? detectedConfs;
  final int? totalConfs;

  PegTransaction({
    required this.txHash,
    required this.vout,
    required this.status,
    required this.amount,
    this.payout,
    this.payoutTxid,
    required this.createdAt,
    required this.txState,
    required this.txStateCode,
    this.detectedConfs,
    this.totalConfs,
  });

  factory PegTransaction.fromJson(Map<String, dynamic> json) {
    TxState state;
    switch (json['tx_state']) {
      case 'InsufficientAmount':
        state = TxState.insufficientAmount;
        break;
      case 'Detected':
        state = TxState.detected;
        break;
      case 'Processing':
        state = TxState.processing;
        break;
      case 'Done':
        state = TxState.done;
        break;
      default:
        state = TxState.unknown;
    }

    return PegTransaction(
      txHash: json['tx_hash'],
      vout: json['vout'],
      status: json['status'],
      amount: json['amount'],
      payout: json['payout'],
      payoutTxid: json['payout_txid'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      txState: state,
      txStateCode: json['tx_state_code'],
      detectedConfs: json['detected_confs'],
      totalConfs: json['total_confs'],
    );
  }
}

/// Response from creating a new peg-in/peg-out order
class PegOrderResponse {
  final String orderId;
  final String pegAddress;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int? receiveAmount;

  PegOrderResponse({
    required this.orderId,
    required this.pegAddress,
    required this.createdAt,
    this.expiresAt,
    this.receiveAmount,
  });

  factory PegOrderResponse.fromJson(Map<String, dynamic> json) {
    return PegOrderResponse(
      orderId: json['order_id'],
      pegAddress: json['peg_addr'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      expiresAt:
          json['expires_at'] != 0
              ? DateTime.fromMillisecondsSinceEpoch(json['expires_at'])
              : null,
      receiveAmount: json['recv_amount'],
    );
  }
}

/// Status of a peg-in/peg-out order
class PegOrderStatus {
  final String orderId;
  final bool isPegIn;
  final String address;
  final String receiveAddress;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<PegTransaction> transactions;

  PegOrderStatus({
    required this.orderId,
    required this.isPegIn,
    required this.address,
    required this.receiveAddress,
    required this.createdAt,
    this.expiresAt,
    required this.transactions,
  });

  factory PegOrderStatus.fromJson(Map<String, dynamic> json) {
    return PegOrderStatus(
      orderId: json['order_id'],
      isPegIn: json['peg_in'],
      address: json['addr'],
      receiveAddress: json['addr_recv'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      expiresAt:
          json['expires_at'] != 0
              ? DateTime.fromMillisecondsSinceEpoch(json['expires_at'])
              : null,
      transactions:
          (json['list'] as List)
              .map((tx) => PegTransaction.fromJson(tx))
              .toList(),
    );
  }
}

/// PegIn balances from the server status
class PegInWalletBalance {
  final int available;

  PegInWalletBalance({required this.available});

  factory PegInWalletBalance.fromJson(Map<String, dynamic> json) {
    return PegInWalletBalance(available: json['available']);
  }
}

/// PegIn balances from the server status
class PegOutWalletBalance {
  final int available;

  PegOutWalletBalance({required this.available});

  factory PegOutWalletBalance.fromJson(Map<String, dynamic> json) {
    return PegOutWalletBalance(available: json['available']);
  }
}

/// Minimum peg-in amount
class PegInMinAmount {
  final int minAmount;

  PegInMinAmount({required this.minAmount});

  factory PegInMinAmount.fromJson(Map<String, dynamic> json) {
    return PegInMinAmount(minAmount: json['min_amount']);
  }
}

/// Server status info
class ServerStatus {
  final double elementsFeeRate;
  final int minPegInAmount;
  final int minPegOutAmount;
  final double serverFeePercentPegIn;
  final double serverFeePercentPegOut;

  ServerStatus({
    required this.elementsFeeRate,
    required this.minPegInAmount,
    required this.minPegOutAmount,
    required this.serverFeePercentPegIn,
    required this.serverFeePercentPegOut,
  });

  factory ServerStatus.fromJson(Map<String, dynamic> json) {
    return ServerStatus(
      elementsFeeRate: json['elements_fee_rate'],
      minPegInAmount: json['min_peg_in_amount'],
      minPegOutAmount: json['min_peg_out_amount'],
      serverFeePercentPegIn: json['server_fee_percent_peg_in'],
      serverFeePercentPegOut: json['server_fee_percent_peg_out'],
    );
  }
}

/// Asset information returned by the assets API
class SideswapAsset {
  final String assetId;
  final bool? alwaysShow;
  final Map<String, dynamic>? contract;
  final String? domain;
  final String? iconUrl;
  final bool? instantSwaps;
  final Map<String, dynamic>? issuancePrevout;
  final String? issuerPubkey;
  final String? marketType;
  final String name;
  final bool? payjoin;
  final int precision;
  final String ticker;

  SideswapAsset({
    required this.assetId,
    this.alwaysShow,
    this.contract,
    this.domain,
    this.iconUrl,
    this.instantSwaps,
    this.issuancePrevout,
    this.issuerPubkey,
    this.marketType,
    required this.name,
    this.payjoin,
    required this.precision,
    required this.ticker,
  });

  factory SideswapAsset.fromJson(Map<String, dynamic> json) {
    return SideswapAsset(
      assetId: json['asset_id'],
      alwaysShow: json['always_show'],
      contract: json['contract'],
      domain: json['domain'],
      iconUrl: json['icon_url'],
      instantSwaps: json['instant_swaps'],
      issuancePrevout: json['issuance_prevout'],
      issuerPubkey: json['issuer_pubkey'],
      marketType: json['market_type'],
      name: json['name'],
      payjoin: json['payjoin'],
      precision: json['precision'],
      ticker: json['ticker'],
    );
  }
}

/// PayJoin UTXO details
class PayJoinUtxo {
  final String txid;
  final int vout;
  final String scriptPubKey;
  final String assetId;
  final int value;
  final String assetBf;
  final String valueBf;
  final String assetCommitment;
  final String valueCommitment;

  PayJoinUtxo({
    required this.txid,
    required this.vout,
    required this.scriptPubKey,
    required this.assetId,
    required this.value,
    required this.assetBf,
    required this.valueBf,
    required this.assetCommitment,
    required this.valueCommitment,
  });

  factory PayJoinUtxo.fromJson(Map<String, dynamic> json) {
    return PayJoinUtxo(
      txid: json['txid'],
      vout: json['vout'],
      scriptPubKey: json['script_pub_key'],
      assetId: json['asset_id'],
      value: json['value'],
      assetBf: json['asset_bf'],
      valueBf: json['value_bf'],
      assetCommitment: json['asset_commitment'],
      valueCommitment: json['value_commitment'],
    );
  }
}

/// Response from starting a PayJoin transaction
class PayJoinStartResponse {
  final String orderId;
  final DateTime expiresAt;
  final double price;
  final int fixedFee;
  final String feeAddress;
  final String changeAddress;
  final List<PayJoinUtxo> utxos;

  PayJoinStartResponse({
    required this.orderId,
    required this.expiresAt,
    required this.price,
    required this.fixedFee,
    required this.feeAddress,
    required this.changeAddress,
    required this.utxos,
  });

  factory PayJoinStartResponse.fromJson(Map<String, dynamic> json) {
    return PayJoinStartResponse(
      orderId: json['order_id'],
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expires_at']),
      price: json['price'],
      fixedFee: json['fixed_fee'],
      feeAddress: json['fee_address'],
      changeAddress: json['change_address'],
      utxos:
          (json['utxos'] as List)
              .map((utxo) => PayJoinUtxo.fromJson(utxo))
              .toList(),
    );
  }
}

/// Current state of a swap operation
class SwapState {
  final Asset? fromAsset;
  final Asset? toAsset;
  final double? amount;
  final SwapDirection direction;
  final SideswapQuote? quote;
  final bool isSubmitting;

  SwapState({
    this.fromAsset,
    this.toAsset,
    this.amount,
    this.direction = SwapDirection.sell,
    this.quote,
    this.isSubmitting = false,
  });

  SwapState copyWith({
    Asset? fromAsset,
    Asset? toAsset,
    double? amount,
    SwapDirection? direction,
    SideswapQuote? quote,
    bool? isSubmitting,
  }) {
    return SwapState(
      fromAsset: fromAsset ?? this.fromAsset,
      toAsset: toAsset ?? this.toAsset,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      quote: quote ?? this.quote,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Asset pair for market operations
class AssetPair {
  final String base;
  final String quote;

  AssetPair({required this.base, required this.quote});

  factory AssetPair.fromJson(Map<String, dynamic> json) {
    return AssetPair(base: json['base'], quote: json['quote']);
  }

  Map<String, dynamic> toJson() {
    return {'base': base, 'quote': quote};
  }
}

/// Chart data point from market data stream
class AssetPairMarketData {
  final double close;
  final double high;
  final double low;
  final double open;
  final String time;
  final double volume;

  AssetPairMarketData({
    required this.close,
    required this.high,
    required this.low,
    required this.open,
    required this.time,
    required this.volume,
  });

  factory AssetPairMarketData.fromJson(Map<String, dynamic> json) {
    return AssetPairMarketData(
      close: json['close'],
      high: json['high'],
      low: json['low'],
      open: json['open'],
      time: json['time'],
      volume: json['volume'],
    );
  }
}

class QuoteRequest {
  String baseAsset;
  String quoteAsset;
  String assetType;
  int amount;
  SwapDirection direction;
  List<SwapUtxo> utxos;
  String receiveAddress;
  String changeAddress;

  QuoteRequest({
    required this.baseAsset,
    required this.quoteAsset,
    required this.assetType,
    required this.amount,
    required this.direction,
    required this.utxos,
    required this.receiveAddress,
    required this.changeAddress,
  });
}
