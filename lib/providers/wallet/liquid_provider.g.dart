// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liquid_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$liquidWalletRepositoryHash() =>
    r'f32648ae37400a2ea72a4cb84af924dbd6fe574b';

/// See also [liquidWalletRepository].
@ProviderFor(liquidWalletRepository)
final liquidWalletRepositoryProvider = Provider<WalletRepository>.internal(
  liquidWalletRepository,
  name: r'liquidWalletRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$liquidWalletRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LiquidWalletRepositoryRef = ProviderRef<WalletRepository>;
String _$liquidWalletNotifierHash() =>
    r'87bb92f6a3ae2f78f5791283b56c28b34102b26a';

/// See also [LiquidWalletNotifier].
@ProviderFor(LiquidWalletNotifier)
final liquidWalletNotifierProvider =
    NotifierProvider<LiquidWalletNotifier, AsyncValue<void>>.internal(
      LiquidWalletNotifier.new,
      name: r'liquidWalletNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$liquidWalletNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LiquidWalletNotifier = Notifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
