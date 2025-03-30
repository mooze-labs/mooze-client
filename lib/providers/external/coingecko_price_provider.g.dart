// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coingecko_price_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$coingeckoPriceHash() => r'9c9296bffffb9f271199397cea5a1bc022eb71b3';

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

/// See also [coingeckoPrice].
@ProviderFor(coingeckoPrice)
const coingeckoPriceProvider = CoingeckoPriceFamily();

/// See also [coingeckoPrice].
class CoingeckoPriceFamily extends Family<AsyncValue<Map<String, double>>> {
  /// See also [coingeckoPrice].
  const CoingeckoPriceFamily();

  /// See also [coingeckoPrice].
  CoingeckoPriceProvider call(CoingeckoAssetPairs coingeckoAssetPairs) {
    return CoingeckoPriceProvider(coingeckoAssetPairs);
  }

  @override
  CoingeckoPriceProvider getProviderOverride(
    covariant CoingeckoPriceProvider provider,
  ) {
    return call(provider.coingeckoAssetPairs);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'coingeckoPriceProvider';
}

/// See also [coingeckoPrice].
class CoingeckoPriceProvider
    extends AutoDisposeFutureProvider<Map<String, double>> {
  /// See also [coingeckoPrice].
  CoingeckoPriceProvider(CoingeckoAssetPairs coingeckoAssetPairs)
    : this._internal(
        (ref) => coingeckoPrice(ref as CoingeckoPriceRef, coingeckoAssetPairs),
        from: coingeckoPriceProvider,
        name: r'coingeckoPriceProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$coingeckoPriceHash,
        dependencies: CoingeckoPriceFamily._dependencies,
        allTransitiveDependencies:
            CoingeckoPriceFamily._allTransitiveDependencies,
        coingeckoAssetPairs: coingeckoAssetPairs,
      );

  CoingeckoPriceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.coingeckoAssetPairs,
  }) : super.internal();

  final CoingeckoAssetPairs coingeckoAssetPairs;

  @override
  Override overrideWith(
    FutureOr<Map<String, double>> Function(CoingeckoPriceRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CoingeckoPriceProvider._internal(
        (ref) => create(ref as CoingeckoPriceRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        coingeckoAssetPairs: coingeckoAssetPairs,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, double>> createElement() {
    return _CoingeckoPriceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CoingeckoPriceProvider &&
        other.coingeckoAssetPairs == coingeckoAssetPairs;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, coingeckoAssetPairs.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CoingeckoPriceRef on AutoDisposeFutureProviderRef<Map<String, double>> {
  /// The parameter `coingeckoAssetPairs` of this provider.
  CoingeckoAssetPairs get coingeckoAssetPairs;
}

class _CoingeckoPriceProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, double>>
    with CoingeckoPriceRef {
  _CoingeckoPriceProviderElement(super.provider);

  @override
  CoingeckoAssetPairs get coingeckoAssetPairs =>
      (origin as CoingeckoPriceProvider).coingeckoAssetPairs;
}

String _$coinGeckoPriceCacheHash() =>
    r'3e78897745b52bcec93384f449ac3b91a83949ae';

/// See also [CoinGeckoPriceCache].
@ProviderFor(CoinGeckoPriceCache)
final coinGeckoPriceCacheProvider =
    AsyncNotifierProvider<CoinGeckoPriceCache, CachedPrices>.internal(
      CoinGeckoPriceCache.new,
      name: r'coinGeckoPriceCacheProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$coinGeckoPriceCacheHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CoinGeckoPriceCache = AsyncNotifier<CachedPrices>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
