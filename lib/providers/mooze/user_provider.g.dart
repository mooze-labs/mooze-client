// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userServiceHash() => r'8dc6238a2bcafe09d180e32aa33abfd5f47f1b00';

/// See also [userService].
@ProviderFor(userService)
final userServiceProvider = AutoDisposeProvider<UserService>.internal(
  userService,
  name: r'userServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserServiceRef = AutoDisposeProviderRef<UserService>;
String _$getUserIdHash() => r'de97c3c134e39145bdff1c35c6c0772b87c9e9cc';

/// See also [getUserId].
@ProviderFor(getUserId)
final getUserIdProvider = AutoDisposeFutureProvider<String?>.internal(
  getUserId,
  name: r'getUserIdProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$getUserIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetUserIdRef = AutoDisposeFutureProviderRef<String?>;
String _$getUserDetailsHash() => r'b8f8ba4bc01ac395ee2025f11b073a49959bbd4b';

/// See also [getUserDetails].
@ProviderFor(getUserDetails)
final getUserDetailsProvider = AutoDisposeFutureProvider<User?>.internal(
  getUserDetails,
  name: r'getUserDetailsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$getUserDetailsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetUserDetailsRef = AutoDisposeFutureProviderRef<User?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
