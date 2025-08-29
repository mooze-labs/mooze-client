import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AmountDisplayMode { fiat, bitcoin, satoshis }

final amountDisplayModeProvider = StateProvider<AmountDisplayMode>((ref) {
  return AmountDisplayMode.fiat;
});

extension AmountDisplayModeExtension on AmountDisplayMode {
  AmountDisplayMode get next {
    switch (this) {
      case AmountDisplayMode.fiat:
        return AmountDisplayMode.bitcoin;
      case AmountDisplayMode.bitcoin:
        return AmountDisplayMode.satoshis;
      case AmountDisplayMode.satoshis:
        return AmountDisplayMode.fiat;
    }
  }

  String get label {
    switch (this) {
      case AmountDisplayMode.fiat:
        return 'R\$';
      case AmountDisplayMode.bitcoin:
        return 'BTC';
      case AmountDisplayMode.satoshis:
        return 'sats';
    }
  }
}
