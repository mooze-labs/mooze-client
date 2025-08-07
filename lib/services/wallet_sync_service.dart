import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mooze_mobile/repositories/wallet/wollet.dart';

class WalletSyncService {
  final WolletRepository wollet;
  Timer? _timer;
  bool _isSyncing = false;

  WalletSyncService({required this.wollet});

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 2), _sync);
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _sync(Timer timer) async {
    if (_isSyncing) return;

    _isSyncing = true;
    try {
      await wollet.sync();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error syncing wallet: $e");
      }
    } finally {
      _isSyncing = false;
    }
  }
}
