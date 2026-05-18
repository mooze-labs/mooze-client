import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/v2_providers.dart';

/// Bridges Flutter's `AppLifecycleState` into the V2 transaction
/// notifier's foreground gate. Mounted near the app root (next to
/// `TransactionStatusListener`); does not render any UI.
///
/// On `AppLifecycleState.resumed` → notifier.setForegrounded(true).
/// On `paused` / `inactive` / `hidden` / `detached` → setForegrounded(false).
///
/// The notifier uses this signal to:
///   - suppress modals while the app is backgrounded
///   - flush its `_pendingEmissions` buffer on resume so any
///     transactions that arrived during the foreground window but
///     before the home gate was open get shown.
///
/// Wallet-delete + re-import: the notifier is rebuilt by Riverpod when
/// `transactionNotifierProvider` is invalidated, so we don't need to
/// reset the foreground flag manually here. The fresh notifier instance
/// defaults to `foregrounded=true`.
class AppForegroundObserver extends ConsumerStatefulWidget {
  final Widget child;

  const AppForegroundObserver({super.key, required this.child});

  @override
  ConsumerState<AppForegroundObserver> createState() =>
      _AppForegroundObserverState();
}

class _AppForegroundObserverState extends ConsumerState<AppForegroundObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foregrounded = state == AppLifecycleState.resumed;
    // Best-effort: the notifier may not be constructed yet if the user
    // is still on splash. In that case the read throws / returns a
    // pending Future; we just drop the signal — the notifier defaults
    // to foregrounded=true on construction anyway, and a subsequent
    // pause/resume cycle will propagate normally.
    ref.read(transactionNotifierProvider.future).then((notifier) {
      notifier.setForegrounded(foregrounded);
    }).catchError((_) {/* notifier not ready yet */});
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
