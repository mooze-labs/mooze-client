enum WalletErrorType {
  insufficientFunds,
  invalidAddress,
  networkError,
  transactionFailed,
  invalidAmount,
  invalidAsset,
}

class WalletError {
  const WalletError(this.type, [this.customDescription]);
  
  final WalletErrorType type;
  final String? customDescription;
  
  String get description {
    if (customDescription != null) {
      return '${_getDefaultDescription(type)}: $customDescription';
    }
    return _getDefaultDescription(type);
  }
  
  String _getDefaultDescription(WalletErrorType type) {
    switch (type) {
      case WalletErrorType.insufficientFunds:
        return 'Fundos insuficientes na carteira.';
      case WalletErrorType.invalidAddress:
        return 'Endereço inválido.';
      case WalletErrorType.networkError:
        return 'Conexão falhou.';
      case WalletErrorType.transactionFailed:
        return 'Transação não pode ser finalizada.';
      case WalletErrorType.invalidAsset:
        return 'Ativo invalido.';
      case WalletErrorType.invalidAmount:
        return 'Valor inválido.';
    }
  }
}