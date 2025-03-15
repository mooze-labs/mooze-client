import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';

part 'wallet_sync_provider.g.dart';

@Riverpod(keepAlive: true)
class WalletSyncService extends _$WalletSyncService {
  Timer? _syncTimer;
  DateTime? _lastSyncTime;
  bool _syncInProgress = false;

  @override
  AsyncValue<DateTime?> build() {
    ref.onDispose(() {
      _stopSyncTimer();
    });

    // Return the last sync time, if available
    return AsyncValue.data(_lastSyncTime);
  }

  void startPeriodicSync() {
    if (_syncTimer != null) {
      return; // Already running
    }

    // Run immediately for the first time
    _syncWallets();

    // Then set up the periodic timer
    _syncTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _syncWallets(),
    );
  }

  void stopPeriodicSync() {
    _stopSyncTimer();
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _syncWallets() async {
    if (_syncInProgress) {
      // Prevent multiple concurrent syncs
      return;
    }

    _syncInProgress = true;
    state = const AsyncValue.loading();

    try {
      debugPrint("🔄 Starting wallet synchronization");

      // Sync Bitcoin wallet
      await ref.read(bitcoinWalletNotifierProvider.notifier).sync();
      debugPrint("✓ Bitcoin wallet synchronized");

      // Sync Liquid wallet
      await ref.read(liquidWalletNotifierProvider.notifier).sync();
      debugPrint("✓ Liquid wallet synchronized");

      // Update the last sync time
      _lastSyncTime = DateTime.now();
      state = AsyncValue.data(_lastSyncTime);
      debugPrint("✅ Wallet sync completed at ${_lastSyncTime.toString()}");
    } catch (e, stackTrace) {
      debugPrint("❌ Wallet sync error: $e");
      state = AsyncValue.error(e, stackTrace);
    } finally {
      _syncInProgress = false;
    }
  }

  // Manual sync method that can be called by the user
  Future<void> syncNow() async {
    return _syncWallets();
  }
}
