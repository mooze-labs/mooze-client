import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
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

    // Stable widget tree (2026-05-24 fix): every branch returns the
    // SAME outer `Stack` with `child` as its base. Previously the
    // `data` and `error` branches returned `child` bare while `loading`
    // wrapped it in a `Stack` — when auth transitioned from loading
    // to data, the tree structure changed and Flutter rebuilt the
    // entire subtree (Scaffold, RefreshIndicator, ScrollView, the
    // 218-item TransactionList). Profile showed a 562ms UI-thread
    // block on that one switch. Always keeping the Stack means the
    // overlay just toggles `isVisible` and the home tree is
    // preserved across auth state transitions.
    final showPill = authState.isLoading;
    if (authState.hasError && errorBuilder != null) {
      return errorBuilder!(
        authState.error!,
        authState.stackTrace ?? StackTrace.empty,
      );
    }
    return Stack(
      children: [
        child,
        if (showPill)
          Positioned(
            top: 40,
            right: 10,
            child: _AuthSyncingPill(),
          ),
      ],
    );
  }
}

class _AuthSyncingPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).auth_syncing,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
