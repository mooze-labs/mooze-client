// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bitcoin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bitcoinWalletRepositoryHash() =>
    r'78c0714c7d7cb7983bf5e2d17224e1081d189523';

/// See also [bitcoinWalletRepository].
@ProviderFor(bitcoinWalletRepository)
final bitcoinWalletRepositoryProvider = Provider<WalletRepository>.internal(
  bitcoinWalletRepository,
  name: r'bitcoinWalletRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$bitcoinWalletRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BitcoinWalletRepositoryRef = ProviderRef<WalletRepository>;
String _$bitcoinWalletNotifierHash() =>
    r'eee8f2bf29291554e2bdafd873fc2375fafeec0c';

/// See also [BitcoinWalletNotifier].
@ProviderFor(BitcoinWalletNotifier)
final bitcoinWalletNotifierProvider =
    NotifierProvider<BitcoinWalletNotifier, AsyncValue<void>>.internal(
      BitcoinWalletNotifier.new,
      name: r'bitcoinWalletNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$bitcoinWalletNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BitcoinWalletNotifier = Notifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
