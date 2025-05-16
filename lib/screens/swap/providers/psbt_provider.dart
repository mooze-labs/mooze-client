import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/models/transaction.dart';

part 'psbt_provider.g.dart';

@riverpod
class Psbt extends _$Psbt {
  @override
  PartiallySignedTransaction? build() {
    return null;
  }

  void set(PartiallySignedTransaction? psbt) {
    state = psbt;
  }

  void clear() {
    state = null;
  }
}
