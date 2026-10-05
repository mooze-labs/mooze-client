import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WalletDisplayMode { fiat, bitcoin, satoshis }

final walletDisplayModeProvider = StateProvider<WalletDisplayMode>((ref) {
  return WalletDisplayMode.fiat;
});

extension WalletDisplayModeExtension on WalletDisplayMode {
  WalletDisplayMode get next {
    switch (this) {
      case WalletDisplayMode.fiat:
        return WalletDisplayMode.bitcoin;
      case WalletDisplayMode.bitcoin:
        return WalletDisplayMode.satoshis;
      case WalletDisplayMode.satoshis:
        return WalletDisplayMode.fiat;
    }
  }
}
