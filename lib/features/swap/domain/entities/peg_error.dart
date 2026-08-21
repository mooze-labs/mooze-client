/// Failure taxonomy for peg operations.
sealed class PegError {
  const PegError();

  /// Portuguese message suitable for a snackbar. Matches the app's existing
  /// user-facing language.
  String get message;
}

/// Amount is below SideSwap's published minimum for this direction.
class PegBelowMinimum extends PegError {
  const PegBelowMinimum({required this.minimumSat, required this.actualSat});
  final int minimumSat;
  final int actualSat;

  @override
  String get message => 'Valor mínimo é $minimumSat sats';
}

/// Wallet cannot cover the amount plus fees.
class PegInsufficientFunds extends PegError {
  const PegInsufficientFunds(this.detail);
  final String detail;

  @override
  String get message => 'Saldo insuficiente: $detail';
}

/// SideSwap rejected the request or returned an unusable payload.
class PegProviderRejected extends PegError {
  const PegProviderRejected(this.detail);
  final String detail;

  @override
  String get message => 'SideSwap recusou a operação: $detail';
}

/// The peg order does not exist (bad order id, or SideSwap forgot it).
class PegOrderNotFound extends PegError {
  const PegOrderNotFound(this.orderId);
  final String orderId;

  @override
  String get message => 'Ordem não encontrada';
}

/// Transport-level problem — socket down, no response in time. Retryable
/// *for reads*; see [PegUnknownOutcome] for writes.
class PegTransportFailure extends PegError {
  const PegTransportFailure(this.detail);
  final String detail;

  @override
  String get message => 'Falha de conexão com a SideSwap. Tente novamente.';
}

/// The wallet could not build, sign, or broadcast the funding transaction.
class PegWalletFailure extends PegError {
  const PegWalletFailure(this.detail);
  final String detail;

  @override
  String get message => 'Erro na carteira: $detail';
}

/// Another Liquid spend is holding the shared UTXO lock.
class PegWalletBusy extends PegError {
  const PegWalletBusy(this.detail);
  final String detail;

  @override
  String get message => detail;
}

class PegUnknownOutcome extends PegError {
  const PegUnknownOutcome({
    required this.stage,
    required this.detail,
    this.orderId,
  });

  /// Where the ambiguity arose: `createOrder`, `broadcast`, …
  final String stage;
  final String detail;

  /// Present when the order was created before the ambiguity — makes
  /// reconciliation possible.
  final String? orderId;

  @override
  String get message =>
      'Não foi possível confirmar a operação. Verifique o histórico '
      'antes de tentar novamente.';
}
