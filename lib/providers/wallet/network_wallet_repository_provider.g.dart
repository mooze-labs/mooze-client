// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_wallet_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$networkWolletRepositoryHash() =>
    r'e98d15cc40b4a223bea5d51851aeee23ff3433a5';

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

/// See also [networkWolletRepository].
@ProviderFor(networkWolletRepository)
const networkWolletRepositoryProvider = NetworkWolletRepositoryFamily();

/// See also [networkWolletRepository].
class NetworkWolletRepositoryFamily extends Family<WolletRepository> {
  /// See also [networkWolletRepository].
  const NetworkWolletRepositoryFamily();

  /// See also [networkWolletRepository].
  NetworkWolletRepositoryProvider call(Network network) {
    return NetworkWolletRepositoryProvider(network);
  }

  @override
  NetworkWolletRepositoryProvider getProviderOverride(
    covariant NetworkWolletRepositoryProvider provider,
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
  String? get name => r'networkWolletRepositoryProvider';
}

/// See also [networkWolletRepository].
class NetworkWolletRepositoryProvider extends Provider<WolletRepository> {
  /// See also [networkWolletRepository].
  NetworkWolletRepositoryProvider(Network network)
    : this._internal(
        (ref) =>
            networkWolletRepository(ref as NetworkWolletRepositoryRef, network),
        from: networkWolletRepositoryProvider,
        name: r'networkWolletRepositoryProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$networkWolletRepositoryHash,
        dependencies: NetworkWolletRepositoryFamily._dependencies,
        allTransitiveDependencies:
            NetworkWolletRepositoryFamily._allTransitiveDependencies,
        network: network,
      );

  NetworkWolletRepositoryProvider._internal(
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
    WolletRepository Function(NetworkWolletRepositoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NetworkWolletRepositoryProvider._internal(
        (ref) => create(ref as NetworkWolletRepositoryRef),
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
  ProviderElement<WolletRepository> createElement() {
    return _NetworkWolletRepositoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NetworkWolletRepositoryProvider && other.network == network;
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
mixin NetworkWolletRepositoryRef on ProviderRef<WolletRepository> {
  /// The parameter `network` of this provider.
  Network get network;
}

class _NetworkWolletRepositoryProviderElement
    extends ProviderElement<WolletRepository>
    with NetworkWolletRepositoryRef {
  _NetworkWolletRepositoryProviderElement(super.provider);

  @override
  Network get network => (origin as NetworkWolletRepositoryProvider).network;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
