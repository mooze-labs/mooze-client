import '../../features/wallet/data/models/transaction_status_event.dart';

/// Emits a [TransactionStatusEvent] when a previously-unnotified incoming
/// transaction transitions to `confirmed`. Used by
/// `TransactionStatusListener` to show the "transaction received"
/// modal + invalidate user-info providers.
///
/// V2 replacement for the legacy `TransactionMonitorService` (which
/// listened to legacy `syncStreamProvider` + `transactionHistoryProvider`).
/// The V2 notifier subscribes to the V2 `SyncOrchestrator.transactions`
/// stream — events arrive only after `transactionStore.upsert` has
/// persisted them (the V2 persist-before-republish invariant).
///
/// ## State machine (post 2026-05-12 redesign)
///
/// The notifier holds three orthogonal state slices:
///
///   - **Baseline phase** — internal-only. `baseliningInProgress` until
///     the first sync settles on a fresh install, then `ready`. During
///     `baseliningInProgress` every observed transaction is silently
///     marked in the persisted dedup registry without emitting, so the
///     wallet's historical txs (loaded from electrum/breez at first
///     boot) do not spam the user with N modals. Sticky once advanced
///     to `ready`; only wallet-delete wipes it back.
///
///   - **Home-reached gate** — true once the user has reached `/home`
///     for the first time in this app session. Set via
///     [setHomeReached]. Blocks emission until then so events from the
///     first post-boot sync don't render over the splash/PIN screen.
///     Sticky for the session — does not unset on app pause.
///
///   - **Foreground gate** — true when the app is in the foreground.
///     Toggled by the `WidgetsBindingObserver` via [setForegrounded].
///     When `false`, events are dropped from the user-facing stream;
///     they are still persisted to the dedup registry so a subsequent
///     cold restart will NOT re-emit them.
///
/// Emission requires **all three** of `baseline == ready`,
/// `homeReached == true`, and `foregrounded == true`. Any one being
/// false suppresses the modal but does not lose the dedup guarantee.
///
/// ## Persistence
///
/// Dedup state lives in the `notified_tx_ids` table of `mooze_v2.db`;
/// the baseline flag lives in `notification_meta`. Both are wiped by
/// `DeleteWalletUseCase` and `ImportWalletUseCase` so a re-import on
/// the same device starts with a clean ledger.
abstract interface class TransactionNotifier {
  /// Broadcast stream of user-facing confirmation events. Subscribers
  /// receive each event at most once across the wallet's lifetime
  /// (persisted dedup).
  Stream<TransactionStatusEvent> get notifications;

  /// Mark that the user has reached `/home`. Sticky for the session.
  /// Called from `HomeScreen.initState`.
  void setHomeReached();

  /// Toggle foreground/background. Called from a `WidgetsBindingObserver`
  /// at the app root in response to `AppLifecycleState.resumed` /
  /// `paused` / `inactive`.
  void setForegrounded(bool foregrounded);

  /// Stop the internal subscription. Idempotent.
  Future<void> dispose();
}
