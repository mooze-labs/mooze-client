import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/authentication/providers/auth_initializer_provider.dart';

class AuthInitializerWidget extends ConsumerWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;

  const AuthInitializerWidget({
    super.key,
    required this.child,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authInitializerProvider);

    if (authState.hasError && errorBuilder != null) {
      return errorBuilder!(
        authState.error!,
        authState.stackTrace ?? StackTrace.empty,
      );
    }

    return Stack(children: [child]);
  }
}
