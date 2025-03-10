// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$liquidNetworkHash() => r'9f930b781b917f4e982535147925c3a4f3261126';

/// See also [LiquidNetwork].
@ProviderFor(LiquidNetwork)
final liquidNetworkProvider =
    AutoDisposeNotifierProvider<LiquidNetwork, Network>.internal(
      LiquidNetwork.new,
      name: r'liquidNetworkProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$liquidNetworkHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LiquidNetwork = AutoDisposeNotifier<Network>;
String _$liquidWalletNotifierHash() =>
    r'ac5bee654fe40fa768807ac5223e129587ab3608';

/// See also [LiquidWalletNotifier].
@ProviderFor(LiquidWalletNotifier)
final liquidWalletNotifierProvider =
    NotifierProvider<LiquidWalletNotifier, AsyncValue<Wallet>>.internal(
      LiquidWalletNotifier.new,
      name: r'liquidWalletNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$liquidWalletNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LiquidWalletNotifier = Notifier<AsyncValue<Wallet>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
