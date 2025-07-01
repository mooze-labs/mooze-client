import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'visibility_provider.g.dart';

@riverpod
class VisibilityProvider extends _$VisibilityProvider {
  @override
  bool build() {
    return true;
  }

  void toggle() {
    state = !state;
  }
}
