import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class TransactionValueFormatter {
  static String formatTransactionValue({required Transaction transaction}) {
    final isReceive = transaction.type == TransactionType.receive;
    final sign = isReceive ? '+' : '-';

    if (transaction.asset == Asset.btc || transaction.asset == Asset.lbtc) {
      final satoshis = transaction.amount.toInt();
      final satText = satoshis == 1 ? 'sat' : 'sats';
      return "$sign$satoshis $satText";
    }

    if (transaction.asset == Asset.usdt) {
      final usdtAmount = transaction.amount.toDouble() / 100000000;
      return "$sign\$ ${usdtAmount.toStringAsFixed(2)}";
    }

    if (transaction.asset == Asset.depix) {
      final depixAmount = transaction.amount.toDouble() / 100000000;
      return "${sign}R\$ ${depixAmount.toStringAsFixed(2)}";
    }

    final amount = transaction.amount.toDouble() / 100000000;
    return "$sign${amount.toStringAsFixed(2)} ${transaction.asset.name.toUpperCase()}";
  }
}
