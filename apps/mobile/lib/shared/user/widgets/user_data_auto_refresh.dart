import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/pix/receive_pix/data/models/pix_status_event.dart';
import 'package:mooze_mobile/features/pix/receive_pix/di/providers/pix_repository_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/pix_repository.dart';
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';

/// Asks `/users/me` again whenever the values to receive may have changed,
/// so the card of the values to receive follows a payment without a
/// restart of the app.
///
/// Once a payer pays a Pix deposit, the API lists the amount in
/// `to_receive` until the asset reaches the wallet. The app learns it on
/// three occasions:
/// - a Pix deposit changes status, in the poll of the app;
/// - a wallet sync ends well, every minute: it covers a payment link and a
///   deposit made on another phone, which the app does not poll;
/// - the app comes back to the foreground, after the payer paid in the
///   bank app.
///
/// It asks only when a screen already reads the user. The answer replaces
/// what shows; a failure keeps it.
///
/// `/users/me` runs the XP check on the server, so the requests stay few:
/// - at most one per [minGap]. A trigger inside the gap is not lost: the
///   triggers of the gap become one request at its end;
/// - with nothing to receive, a sync asks once per [idleSyncGap]. It only
///   looks for a payment that came from elsewhere. While an amount waits,
///   each sync asks, so the card leaves soon after the asset arrives.
///
/// With the app open and nothing to receive, that is one request every 5
/// minutes; while an amount waits, about one a minute, plus the statuses of
/// a Pix deposit.
///
/// Mount it around the main screens: the wallet sync exists only once the
/// wallet is open.
class UserDataAutoRefresh extends ConsumerStatefulWidget {
  const UserDataAutoRefresh({
    super.key,
    required this.child,
    this.now = DateTime.now,
  });

  final Widget child;

  /// The clock. Tests move it.
  final DateTime Function() now;

  /// Shortest time between two requests.
  static const minGap = Duration(seconds: 30);

  /// Time between two requests of the wallet sync while nothing is to
  /// receive.
  static const idleSyncGap = Duration(minutes: 5);

  @override
  ConsumerState<UserDataAutoRefresh> createState() =>
      _UserDataAutoRefreshState();
}

class _UserDataAutoRefreshState extends ConsumerState<UserDataAutoRefresh>
    with WidgetsBindingObserver {
  StreamSubscription<PixStatusEvent>? _pixStatus;
  ProviderSubscription<PixRepository>? _pixRepository;
  ProviderSubscription<AsyncValue<SyncState>>? _sync;

  /// When the last request left. Null before the first.
  DateTime? _lastAsked;

  /// The request that waits for the end of the gap.
  Timer? _waiting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pixRepository = ref.listenManual(pixRepositoryProvider, (_, repository) {
      _pixStatus?.cancel();
      _pixStatus = repository.statusUpdates.listen((_) => _refresh());
    }, fireImmediately: true);
    _sync = ref.listenManual(syncStateProvider, (previous, next) {
      final at = next.valueOrNull?.lastSuccessAt;
      if (at != null && at != previous?.valueOrNull?.lastSuccessAt) {
        _onSync();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _onSync() {
    final last = _lastAsked;
    final idle =
        last != null &&
        widget.now().difference(last) < UserDataAutoRefresh.idleSyncGap;
    if (idle && !_hasToReceive()) return;
    _refresh();
  }

  /// True when the user shows an amount to receive.
  bool _hasToReceive() =>
      ref
          .read(userDataProvider)
          .valueOrNull
          ?.fold(
            (_) => false,
            (user) => user.valuesToReceive.values.any((v) => v > 0),
          ) ??
      false;

  /// Asks now, or at the end of the gap of the last request.
  void _refresh() {
    if (!mounted || !ref.exists(userDataProvider)) return;
    if (_waiting != null) return;
    final last = _lastAsked;
    final since = last == null ? null : widget.now().difference(last);
    if (since != null && since < UserDataAutoRefresh.minGap) {
      _waiting = Timer(UserDataAutoRefresh.minGap - since, () {
        _waiting = null;
        _ask();
      });
      return;
    }
    _ask();
  }

  /// [dispose] cancels a request that waits, so the widget is mounted here.
  void _ask() {
    _lastAsked = widget.now();
    unawaited(ref.read(userDataProvider.notifier).refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waiting?.cancel();
    _pixStatus?.cancel();
    _pixRepository?.close();
    _sync?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
