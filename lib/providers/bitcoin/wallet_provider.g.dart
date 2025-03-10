// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$blockchainHash() => r'ec14570d71e2bb0508db232dc5c6236e60fed378';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [blockchain].
@ProviderFor(blockchain)
const blockchainProvider = BlockchainFamily();

/// See also [blockchain].
class BlockchainFamily extends Family<AsyncValue<Blockchain?>> {
  /// See also [blockchain].
  const BlockchainFamily();

  /// See also [blockchain].
  BlockchainProvider call(Network network) {
    return BlockchainProvider(network);
  }

  @override
  BlockchainProvider getProviderOverride(
    covariant BlockchainProvider provider,
  ) {
    return call(provider.network);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'blockchainProvider';
}

/// See also [blockchain].
class BlockchainProvider extends AutoDisposeFutureProvider<Blockchain?> {
  /// See also [blockchain].
  BlockchainProvider(Network network)
    : this._internal(
        (ref) => blockchain(ref as BlockchainRef, network),
        from: blockchainProvider,
        name: r'blockchainProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$blockchainHash,
        dependencies: BlockchainFamily._dependencies,
        allTransitiveDependencies: BlockchainFamily._allTransitiveDependencies,
        network: network,
      );

  BlockchainProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.network,
  }) : super.internal();

  final Network network;

  @override
  Override overrideWith(
    FutureOr<Blockchain?> Function(BlockchainRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BlockchainProvider._internal(
        (ref) => create(ref as BlockchainRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        network: network,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Blockchain?> createElement() {
    return _BlockchainProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BlockchainProvider && other.network == network;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, network.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BlockchainRef on AutoDisposeFutureProviderRef<Blockchain?> {
  /// The parameter `network` of this provider.
  Network get network;
}

class _BlockchainProviderElement
    extends AutoDisposeFutureProviderElement<Blockchain?>
    with BlockchainRef {
  _BlockchainProviderElement(super.provider);

  @override
  Network get network => (origin as BlockchainProvider).network;
}

String _$bitcoinNetworkHash() => r'5b1770b2632dacea44d669d9540da05723773fcf';

/// See also [BitcoinNetwork].
@ProviderFor(BitcoinNetwork)
final bitcoinNetworkProvider =
    AutoDisposeNotifierProvider<BitcoinNetwork, Network>.internal(
      BitcoinNetwork.new,
      name: r'bitcoinNetworkProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$bitcoinNetworkHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BitcoinNetwork = AutoDisposeNotifier<Network>;
String _$bitcoinWalletNotifierHash() =>
    r'0ecba3f7dec171137c08810c1c6c7ef06edc4bd3';

/// See also [BitcoinWalletNotifier].
@ProviderFor(BitcoinWalletNotifier)
final bitcoinWalletNotifierProvider =
    NotifierProvider<BitcoinWalletNotifier, AsyncValue<Wallet>>.internal(
      BitcoinWalletNotifier.new,
      name: r'bitcoinWalletNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$bitcoinWalletNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BitcoinWalletNotifier = Notifier<AsyncValue<Wallet>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
