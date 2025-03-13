// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_wallet_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$walletRepositoryHash() => r'b6e7aa1b31cbd3e21f7c36ed211b4f1207fa4916';

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

/// See also [walletRepository].
@ProviderFor(walletRepository)
const walletRepositoryProvider = WalletRepositoryFamily();

/// See also [walletRepository].
class WalletRepositoryFamily extends Family<WalletRepository> {
  /// See also [walletRepository].
  const WalletRepositoryFamily();

  /// See also [walletRepository].
  WalletRepositoryProvider call(Network network) {
    return WalletRepositoryProvider(network);
  }

  @override
  WalletRepositoryProvider getProviderOverride(
    covariant WalletRepositoryProvider provider,
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
  String? get name => r'walletRepositoryProvider';
}

/// See also [walletRepository].
class WalletRepositoryProvider extends Provider<WalletRepository> {
  /// See also [walletRepository].
  WalletRepositoryProvider(Network network)
    : this._internal(
        (ref) => walletRepository(ref as WalletRepositoryRef, network),
        from: walletRepositoryProvider,
        name: r'walletRepositoryProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$walletRepositoryHash,
        dependencies: WalletRepositoryFamily._dependencies,
        allTransitiveDependencies:
            WalletRepositoryFamily._allTransitiveDependencies,
        network: network,
      );

  WalletRepositoryProvider._internal(
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
    WalletRepository Function(WalletRepositoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WalletRepositoryProvider._internal(
        (ref) => create(ref as WalletRepositoryRef),
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
  ProviderElement<WalletRepository> createElement() {
    return _WalletRepositoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WalletRepositoryProvider && other.network == network;
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
mixin WalletRepositoryRef on ProviderRef<WalletRepository> {
  /// The parameter `network` of this provider.
  Network get network;
}

class _WalletRepositoryProviderElement extends ProviderElement<WalletRepository>
    with WalletRepositoryRef {
  _WalletRepositoryProviderElement(super.provider);

  @override
  Network get network => (origin as WalletRepositoryProvider).network;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
