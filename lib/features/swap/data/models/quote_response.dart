import 'sideswap_quote.dart';
import 'quote_error.dart';
import 'quote_low_balance.dart';

/// Represents a quote response which could be a success, error, or low balance.
///
/// **Identity fields**
///
/// Every quote message that arrives on the SideSwap WebSocket includes
/// `quote_sub_id`, `amount` (the requested amount), and `asset_pair` —
/// the metadata that tells you *which* `start_quotes` subscription this
/// emission belongs to. The data layer's stream is a shared firehose
/// across every subscription that's ever been opened on the connection,
/// so consumers MUST filter by these identity fields before treating
/// an emission as a response to a specific request.
///
/// The fields are nullable because:
/// - Some synthetic [QuoteResponse]s injected from the service (e.g.
///   connection-error / timeout) don't originate from a server message
///   and may not carry full identity.
/// - Legacy/test inputs that didn't supply these fields still parse.
///
/// Consumers (notably the swap controller's listener) should compare
/// `baseAssetId`, `quoteAssetId`, and `requestedAmount` against the
/// values of their own outstanding request and drop non-matching
/// emissions.
class QuoteResponse {
  final SideswapQuote? quote;
  final QuoteError? error;
  final QuoteLowBalance? lowBalance;

  // ── Identity / disambiguation ───────────────────────────────────────
  final int? quoteSubId;
  final int? requestedAmount;
  final String? baseAssetId;
  final String? quoteAssetId;

  QuoteResponse({
    this.quote,
    this.error,
    this.lowBalance,
    this.quoteSubId,
    this.requestedAmount,
    this.baseAssetId,
    this.quoteAssetId,
  });

  factory QuoteResponse.fromJson(Map<String, dynamic> json) {
    final assetPair = json['asset_pair'] as Map<String, dynamic>?;
    final identity = _QuoteIdentity(
      quoteSubId: (json['quote_sub_id'] as num?)?.toInt(),
      requestedAmount: (json['amount'] as num?)?.toInt(),
      baseAssetId: assetPair?['base'] as String?,
      quoteAssetId: assetPair?['quote'] as String?,
    );

    final status = json['status'];
    if (status is Map<String, dynamic>) {
      if (status.containsKey('Success')) {
        return QuoteResponse(
          quote: SideswapQuote.fromJson(json),
          quoteSubId: identity.quoteSubId,
          requestedAmount: identity.requestedAmount,
          baseAssetId: identity.baseAssetId,
          quoteAssetId: identity.quoteAssetId,
        );
      } else if (status.containsKey('Error')) {
        return QuoteResponse(
          error: QuoteError.fromJson(json),
          quoteSubId: identity.quoteSubId,
          requestedAmount: identity.requestedAmount,
          baseAssetId: identity.baseAssetId,
          quoteAssetId: identity.quoteAssetId,
        );
      } else if (status.containsKey('LowBalance')) {
        return QuoteResponse(
          lowBalance: QuoteLowBalance.fromJson(json),
          quoteSubId: identity.quoteSubId,
          requestedAmount: identity.requestedAmount,
          baseAssetId: identity.baseAssetId,
          quoteAssetId: identity.quoteAssetId,
        );
      }
    }
    return QuoteResponse(
      error: QuoteError(errorMessage: "Unknown quote response"),
      quoteSubId: identity.quoteSubId,
      requestedAmount: identity.requestedAmount,
      baseAssetId: identity.baseAssetId,
      quoteAssetId: identity.quoteAssetId,
    );
  }

  bool get isSuccess => quote != null;
  bool get isError => error != null;
  bool get isLowBalance => lowBalance != null;

  /// True iff this response's identity matches the supplied request
  /// triplet. Null identity fields are treated as non-matches — except
  /// for `quoteSubId`, which the controller may not know yet (the
  /// service returns it asynchronously after `start_quotes`).
  bool matchesRequest({
    required String baseAssetId,
    required String quoteAssetId,
    required int requestedAmount,
  }) {
    return this.baseAssetId == baseAssetId &&
        this.quoteAssetId == quoteAssetId &&
        this.requestedAmount == requestedAmount;
  }
}

class _QuoteIdentity {
  final int? quoteSubId;
  final int? requestedAmount;
  final String? baseAssetId;
  final String? quoteAssetId;
  const _QuoteIdentity({
    this.quoteSubId,
    this.requestedAmount,
    this.baseAssetId,
    this.quoteAssetId,
  });
}
