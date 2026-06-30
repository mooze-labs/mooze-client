import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/app/lifecycle/app_state.dart';
import 'package:mooze_mobile/features/merchant/presentation/providers/usecase_providers.dart';
import 'package:mooze_mobile/features/wallet/data/models/transaction_status_event.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/transaction_confirmed_screen.dart';
import 'package:mooze_mobile/routes.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';

/// V2 tree-wide listener. Subscribes to [transactionNotifierProvider]
/// once the app reaches `AppPhase.ready`, then shows the
/// `TransactionConfirmedScreen` modal each time the notifier emits a
/// (gated, persisted-dedup) confirmation event.
///
/// **Dedup is now the notifier's job** — see `V2TransactionNotifier` —
/// so this widget no longer keeps an in-memory `Set<String>` of
/// processed transaction ids. It also no longer guards against
/// pre-home / pre-foreground events because the notifier holds them in
/// its `_pendingEmissions` buffer and only releases them once both
/// gates open.
///
/// Two things this widget DOES gate locally:
///   1. **Merchant mode** — when merchant mode is active the listener
///      drops events without showing the modal. Notifier remains
///      domain-pure and unaware of presentation modes.
///   2. **Subscription lifecycle** — the `StreamSubscription` is
///      attached once `appLifecycleControllerProvider` resolves and
///      cancelled in `dispose()`. `_isInitialized` keeps the attach
///      idempotent against Riverpod rebuilds.
class TransactionStatusListener extends ConsumerStatefulWidget {
  final Widget child;

  const TransactionStatusListener({super.key, required this.child});

  @override
  ConsumerState<TransactionStatusListener> createState() =>
      _TransactionStatusListenerState();
}

class _TransactionStatusListenerState
    extends ConsumerState<TransactionStatusListener> {
  StreamSubscription<TransactionStatusEvent>? _subscription;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _maybeStart();
  }

  void _maybeStart() {
    final appPhase = ref.read(appStateProvider).valueOrNull?.phase;
    if (appPhase == AppPhase.ready && !_isInitialized) {
      _isInitialized = true;
      _attachListener();
    }
  }

  Future<void> _attachListener() async {
    try {
      final notifier = await ref.read(transactionNotifierProvider.future);
      if (!mounted) {
        // Widget unmounted while awaiting notifier construction —
        // ensure we don't leak a subscription on the rebuilt instance.
        return;
      }
      _subscription = notifier.notifications.listen(_onEvent);
    } catch (e) {
      debugPrint('[TransactionStatusListener] notifier wire failed: $e');
    }
  }

  Future<void> _onEvent(TransactionStatusEvent event) async {
    if (!mounted) return;

    // Merchant-mode suppression. The PIX listener owns merchant-mode
    // confirmations separately; this listener must stay silent for
    // generic on-chain receives while the merchant flow is active.
    if (await _isMerchantModeActive()) {
      return;
    }

    ref.invalidate(userDataProvider);

    // The Future.delayed gives the navigator a frame to settle if the
    // user just arrived at /home. The notifier already gated on
    // `homeReached`, so the navigator should always have a context;
    // the null check is belt-and-suspenders.
    //
    // `rootNavigatorKey.currentContext` is resolved freshly inside the
    // callback (not captured across the async gap), so the lint's
    // concern doesn't apply — `mounted` is also re-checked. Suppress
    // the false positive at the call site.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final navigatorContext = rootNavigatorKey.currentContext;
      if (navigatorContext == null) return;
      try {
        final asset = Asset.fromId(event.assetId);
        TransactionConfirmedScreen.show(
          // ignore: use_build_context_synchronously
          navigatorContext,
          asset: asset,
          amount: event.amount,
          transactionId: event.transactionId,
        );
      } catch (e) {
        debugPrint('Error showing confirmation screen: $e');
      }
    });
  }

  Future<bool> _isMerchantModeActive() async {
    try {
      final usecase = ref.read(checkMerchantModeUseCaseProvider);
      final result = await usecase();
      // The `Result` wrapper used here is Success<bool>/Failure<bool>.
      // Defensive: if the call throws or returns failure, treat as
      // "not merchant" and let the modal show — matches prior
      // behaviour where merchant gating did not exist at all.
      try {
        // ignore: avoid_dynamic_calls
        final dynamic dyn = result;
        if (dyn is bool) return dyn;
        if (dyn.data is bool) return dyn.data as bool;
      } catch (_) {}
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Start listening once the orchestrator is up. Idempotent — gated on
    // `_isInitialized`.
    ref.listen<AsyncValue<AppState>>(appStateProvider, (previous, next) {
      final phase = next.valueOrNull?.phase;
      if (!_isInitialized && phase == AppPhase.ready) {
        _isInitialized = true;
        _attachListener();
      }
    });

    return widget.child;
  }
}
