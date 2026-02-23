import 'sideswap_quote.dart';
import 'quote_error.dart';
import 'quote_low_balance.dart';

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
