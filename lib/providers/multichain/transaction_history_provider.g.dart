// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionHistoryHash() =>
    r'b0da95f3ad83a83228cb20a5fb33a0414d0aa616';

/// See also [TransactionHistory].
@ProviderFor(TransactionHistory)
final transactionHistoryProvider =
    AsyncNotifierProvider<TransactionHistory, List<TransactionRecord>>.internal(
      TransactionHistory.new,
      name: r'transactionHistoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$transactionHistoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TransactionHistory = AsyncNotifier<List<TransactionRecord>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
