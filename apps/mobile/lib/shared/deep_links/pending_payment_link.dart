import 'package:flutter/foundation.dart';

/// Holds an incoming payment URI (`bitcoin:`, `liquidnetwork:`, `liquid:`)
/// until a screen that can act on it is mounted.
///
/// Deep links arrive through the platform router before boot has finished,
/// or while the user is somewhere unrelated. The router captures the URI
/// here and continues to the last good location; the home screen consumes
/// it once the wallet is ready and opens the send flow prefilled.
class PendingPaymentLink {
  PendingPaymentLink._();

  static const Set<String> schemes = {'bitcoin', 'liquidnetwork', 'liquid'};

  static final ValueNotifier<String?> value = ValueNotifier<String?>(null);

  static bool isPaymentUri(Uri uri) =>
      schemes.contains(uri.scheme.toLowerCase());

  /// Stores [uri] when it is a payment link. Returns `false` otherwise.
  static bool tryCapture(Uri uri) {
    if (!isPaymentUri(uri)) return false;
    value.value = toRaw(uri);
    return true;
  }

  /// Rebuilds the wire form the wallet parsers expect (`scheme:address?q`).
  ///
  /// Flutter and go_router may normalise the path with a leading slash; the
  /// address parsers want it bare.
  static String toRaw(Uri uri) {
    var path = uri.path;
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    final query = uri.hasQuery && uri.query.isNotEmpty ? '?${uri.query}' : '';
    return '${uri.scheme.toLowerCase()}:$path$query';
  }

  /// Returns the pending link and clears it.
  static String? take() {
    final current = value.value;
    value.value = null;
    return current;
  }
}
