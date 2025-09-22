import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityState {
  final bool isOnline;
  final DateTime lastUpdate;

  ConnectivityState({required this.isOnline, required this.lastUpdate});

  ConnectivityState copyWith({bool? isOnline, DateTime? lastUpdate}) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  Timer? _connectivityTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();

  ConnectivityNotifier()
    : super(ConnectivityState(isOnline: true, lastUpdate: DateTime.now())) {
    _initConnectivityMonitoring();
  }

  void _initConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    _startPeriodicConnectivityCheck();

    _checkInitialConnectivity();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasNetworkConnection = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );

    if (!hasNetworkConnection) {
      markOffline();
    } else {
      _checkRealConnectivity();
    }
  }

  Future<void> _checkInitialConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _onConnectivityChanged(connectivityResult);
  }

  void _startPeriodicConnectivityCheck() {
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkRealConnectivity(),
    );
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void stopConnectivityCheck() {
    dispose();
  }

  Future<void> _checkRealConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (!state.isOnline) {
          _markOnlineInternal();
        }
      } else {
        markOffline();
      }
    } catch (e) {
      markOffline();
    }
  }

  Future<void> checkConnectivity() async {
    await _checkRealConnectivity();
  }

  void _markOnlineInternal() {
    state = state.copyWith(isOnline: true, lastUpdate: DateTime.now());
  }

  void markOnline() {
    _connectivity.checkConnectivity().then((result) {
      final hasNetworkConnection = result.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet,
      );

      if (hasNetworkConnection) {
        _markOnlineInternal();
      } else {
        // No network
      }
    });
  }

  void markOffline() {
    state = state.copyWith(isOnline: false);
  }

  void updateLastCheck() {
    state = state.copyWith(lastUpdate: DateTime.now());
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
      ref.keepAlive();
      return ConnectivityNotifier();
    });

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).isOnline;
});

final isUsingCacheProvider = Provider<bool>((ref) {
  return !ref.watch(connectivityProvider).isOnline;
});

final connectivityCheckerProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(connectivityProvider.notifier).checkConnectivity();
  };
});
