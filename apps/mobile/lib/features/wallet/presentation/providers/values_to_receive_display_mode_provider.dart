import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ValuesToReceiveDisplayMode { fiat, native }

extension ValuesToReceiveDisplayModeExtension on ValuesToReceiveDisplayMode {
  ValuesToReceiveDisplayMode get toggle {
    switch (this) {
      case ValuesToReceiveDisplayMode.fiat:
        return ValuesToReceiveDisplayMode.native;
      case ValuesToReceiveDisplayMode.native:
        return ValuesToReceiveDisplayMode.fiat;
    }
  }
}

final valuesToReceiveDisplayModeProvider =
    StateProvider.autoDispose<ValuesToReceiveDisplayMode>(
      (ref) => ValuesToReceiveDisplayMode.fiat,
    );
