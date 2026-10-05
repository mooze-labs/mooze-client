import 'package:flutter/widgets.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

enum WalletErrorType {
  insufficientFunds,
  invalidAddress,
  networkError,
  transactionFailed,
  invalidAmount,
  invalidAsset,
  connectionError,
  sdkError,
}

class WalletError {
  const WalletError(this.type, [this.customDescription]);

  final WalletErrorType type;
  final String? customDescription;

  /// Locale-agnostic fallback used in logs / toString. UI should call [localize].
  String get description {
    if (customDescription != null) {
      return '${_getDefaultDescription(type)}: $customDescription';
    }
    return _getDefaultDescription(type);
  }

  /// Returns the user-facing localized message via ARB.
  String localize(BuildContext context) {
    final base = _localizedDescription(context, type);
    if (customDescription != null) {
      return '$base: $customDescription';
    }
    return base;
  }

  @override
  String toString() {
    return 'WalletError(type: $type, description: $description, customDescription: $customDescription)';
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
      case WalletErrorType.connectionError:
        return 'Erro de conexão';
      case WalletErrorType.sdkError:
        return 'Falha interna';
    }
  }

  String _localizedDescription(BuildContext context, WalletErrorType type) {
    final t = AppLocalizations.of(context);
    switch (type) {
      case WalletErrorType.insufficientFunds:
        return t.wallet_errors_insufficient_funds;
      case WalletErrorType.invalidAddress:
        return t.wallet_errors_invalid_address;
      case WalletErrorType.networkError:
        return t.wallet_errors_connection_failed;
      case WalletErrorType.transactionFailed:
        return t.wallet_errors_tx_cannot_finalize;
      case WalletErrorType.invalidAsset:
        return t.wallet_errors_invalid_asset;
      case WalletErrorType.invalidAmount:
        return t.wallet_errors_invalid_amount;
      case WalletErrorType.connectionError:
        return t.wallet_errors_connection;
      case WalletErrorType.sdkError:
        return t.wallet_errors_internal;
    }
  }
}
