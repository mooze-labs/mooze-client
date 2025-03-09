// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pix_gateway_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pixGatewayRepositoryHash() =>
    r'bffb263429a4c40305045f83b689435dc5088cdd';

/// See also [pixGatewayRepository].
@ProviderFor(pixGatewayRepository)
final pixGatewayRepositoryProvider =
    AutoDisposeProvider<PixGatewayRepository>.internal(
      pixGatewayRepository,
      name: r'pixGatewayRepositoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$pixGatewayRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PixGatewayRepositoryRef = AutoDisposeProviderRef<PixGatewayRepository>;
String _$pixPaymentHash() => r'0ef5cc442ecc7c7044b344e1116ef0622336c8f9';

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

/// See also [pixPayment].
@ProviderFor(pixPayment)
const pixPaymentProvider = PixPaymentFamily();

/// See also [pixPayment].
class PixPaymentFamily extends Family<AsyncValue<PixTransactionResponse?>> {
  /// See also [pixPayment].
  const PixPaymentFamily();

  /// See also [pixPayment].
  PixPaymentProvider call(PixTransaction transaction) {
    return PixPaymentProvider(transaction);
  }

  @override
  PixPaymentProvider getProviderOverride(
    covariant PixPaymentProvider provider,
  ) {
    return call(provider.transaction);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'pixPaymentProvider';
}

/// See also [pixPayment].
class PixPaymentProvider
    extends AutoDisposeFutureProvider<PixTransactionResponse?> {
  /// See also [pixPayment].
  PixPaymentProvider(PixTransaction transaction)
    : this._internal(
        (ref) => pixPayment(ref as PixPaymentRef, transaction),
        from: pixPaymentProvider,
        name: r'pixPaymentProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$pixPaymentHash,
        dependencies: PixPaymentFamily._dependencies,
        allTransitiveDependencies: PixPaymentFamily._allTransitiveDependencies,
        transaction: transaction,
      );

  PixPaymentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.transaction,
  }) : super.internal();

  final PixTransaction transaction;

  @override
  Override overrideWith(
    FutureOr<PixTransactionResponse?> Function(PixPaymentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PixPaymentProvider._internal(
        (ref) => create(ref as PixPaymentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        transaction: transaction,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PixTransactionResponse?> createElement() {
    return _PixPaymentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PixPaymentProvider && other.transaction == transaction;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, transaction.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PixPaymentRef on AutoDisposeFutureProviderRef<PixTransactionResponse?> {
  /// The parameter `transaction` of this provider.
  PixTransaction get transaction;
}

class _PixPaymentProviderElement
    extends AutoDisposeFutureProviderElement<PixTransactionResponse?>
    with PixPaymentRef {
  _PixPaymentProviderElement(super.provider);

  @override
  PixTransaction get transaction => (origin as PixPaymentProvider).transaction;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
