import 'dart:async';

import 'mutex.dart';

class LiquidSpendCoordinator {
  LiquidSpendCoordinator({Duration? acquireTimeout})
    : _acquireTimeout = acquireTimeout ?? const Duration(seconds: 90);

  static final LiquidSpendCoordinator instance = LiquidSpendCoordinator();

  final Mutex _mutex = Mutex();
  final Duration _acquireTimeout;

  String? _holder;
  String? get currentHolder => _holder;

  bool get isBusy => _mutex.isLocked;

  Future<T> protect<T>(
    String label,
    Future<T> Function() body, {
    Future<void> Function()? beforeSpend,
    Future<void> Function()? afterSpend,
  }) async {
    final acquired = Completer<void>();
    final section = _mutex.protect(() async {
      if (!acquired.isCompleted) acquired.complete();
      _holder = label;
      try {
        if (beforeSpend != null) await beforeSpend();
        return await body();
      } finally {
        if (afterSpend != null) {
          try {
            await afterSpend();
          } catch (_) {}
        }
        _holder = null;
      }
    });

    try {
      await acquired.future.timeout(_acquireTimeout);
    } on TimeoutException {
      unawaited(section.then<void>((_) {}, onError: (Object _) {}));
      throw LiquidSpendLockTimeout(label, _holder, _acquireTimeout);
    }

    return section;
  }
}

class LiquidSpendLockTimeout implements Exception {
  LiquidSpendLockTimeout(this.waiter, this.holder, this.timeout);

  final String waiter;
  final String? holder;
  final Duration timeout;

  @override
  String toString() =>
      'Outra operação Liquid está em andamento'
      '${holder != null ? ' ($holder)' : ''}. Tente novamente em instantes.';

  /// Untranslated detail for logs.
  String get diagnostic =>
      'LiquidSpendLockTimeout: "$waiter" waited ${timeout.inSeconds}s for '
      '"${holder ?? 'unknown'}"';
}
