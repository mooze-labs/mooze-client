/// Why a Pix hub operation did not finish.
enum PixHubErrorCode {
  /// The data could not be loaded.
  loadFailed,

  /// The simulated payment was declined.
  paymentDeclined,

  /// The typed key does not match any recipient in the demonstration data.
  recipientNotFound,

  /// The amount is outside the accepted range.
  amountOutOfBounds,

  /// The request did not reach the server: no connection or a timeout.
  network,

  /// The session token is missing or the server rejected it after a refresh.
  sessionUnavailable,

  /// The account cannot use the feature yet, for example its level is too low.
  notEligible,

  /// The server limits the number of requests. The user must wait.
  rateLimited,

  /// The service is off, in maintenance or blocked before the server.
  serviceUnavailable,

  /// The server answered success without the expected data.
  invalidResponse,

  /// The wallet could not give a receive address.
  walletUnavailable,

  /// The server rejected the withdrawal data (HTTP 400).
  invalidRequest,

  /// The amount exceeds the allowance, or the account cannot withdraw
  /// (HTTP 403).
  limitExceeded,

  /// The Pix provider refused the withdrawal, for example because the key
  /// does not belong to the tax ID (HTTP 422).
  providerRefused,

  /// The backend does not know if the provider created the withdrawal
  /// (HTTP 503). No funds left the wallet.
  outcomeUnknown,

  /// The withdrawal answer does not match the request or the contract.
  quoteMismatch,

  /// The funding deadline of the withdrawal passed.
  quoteExpired,

  /// The DePix balance does not cover the transfer.
  insufficientFunds,

  /// The L-BTC balance does not cover the Liquid network fee.
  insufficientFeeAsset,

  /// The wallet could not build or sign the transfer. No funds left it.
  fundingFailed,

  /// The Pix code has no Pix key. Withdrawals accept a key only.
  unsupportedCode,

  /// Any other error.
  unknown,
}

/// A failure returned by the Pix hub repository.
class PixHubFailure {
  final PixHubErrorCode code;

  /// Original message, kept for logs. Screens show a translated text instead.
  final String? rawMessage;

  const PixHubFailure(this.code, {this.rawMessage});

  @override
  String toString() => 'PixHubFailure(${code.name}, $rawMessage)';
}
