import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/peg_operation.dart';

part 'peg_operation_provider.g.dart';

@riverpod
class PegOperationProvider extends _$PegOperationProvider {
  @override
  PegOperation? build() {
    return null;
  }

  void setPegOperation(PegOperation operation) {
    state = operation;
  }

  void clearPegOperation() {
    state = null;
  }
}
