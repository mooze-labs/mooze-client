import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_display_mode_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class TransactionValueFormatter {
  static String formatTransactionValue({
    required Transaction transaction,
    required WalletDisplayMode displayMode,
    required double? bitcoinPrice,
    required String currencySymbol,
  }) {
    final isReceive = transaction.type == TransactionType.receive;
    final sign = isReceive ? '+' : '-';

    switch (displayMode) {
      case WalletDisplayMode.fiat:
        return _formatFiatValue(
          transaction: transaction,
          bitcoinPrice: bitcoinPrice,
          currencySymbol: currencySymbol,
          sign: sign,
        );

      case WalletDisplayMode.bitcoin:
        return _formatBitcoinValue(transaction: transaction, sign: sign);

      case WalletDisplayMode.satoshis:
        return _formatSatoshisValue(transaction: transaction, sign: sign);
    }
  }

  static String _formatFiatValue({
    required Transaction transaction,
    required double? bitcoinPrice,
    required String currencySymbol,
    required String sign,
  }) {
    if (bitcoinPrice == null || bitcoinPrice == 0) {
      return "$sign--";
    }

    if (transaction.asset == Asset.btc) {
      final btcAmount = transaction.amount.toDouble() / 100000000;
      final fiatValue = btcAmount * bitcoinPrice;
      return "$sign$currencySymbol ${fiatValue.toStringAsFixed(2)}";
    } else {
      final fiatValue = transaction.amount.toDouble();
      return "$sign$currencySymbol ${fiatValue.toStringAsFixed(2)}";
    }
  }

  static String _formatBitcoinValue({
    required Transaction transaction,
    required String sign,
  }) {
    if (transaction.asset == Asset.btc) {
      final btcAmount = transaction.amount.toDouble() / 100000000;
      return "$sign${btcAmount.toStringAsFixed(8)} BTC";
    } else {
      return "$sign -- BTC";
    }
  }

  static String _formatSatoshisValue({
    required Transaction transaction,
    required String sign,
  }) {
    if (transaction.asset == Asset.btc) {
      final satoshis = transaction.amount.toInt();
      final satText = satoshis == 1 ? 'sat' : 'sats';
      return "$sign$satoshis $satText";
    } else {
      return "$sign -- sats";
    }
  }
}
