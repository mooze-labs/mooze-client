import '../../domain/entities/chain.dart';
import '../../domain/services/electrum_endpoint_resolver.dart';

/// Round-robin Electrum endpoint resolver with stickiness-on-success.
///
/// Each chain owns its own server list and rotation cursor. The cursor
/// only advances when `reportFailure` is called more than
/// [failureThreshold] times in a row for the current endpoint; on
/// `reportSuccess` the cursor pins to the current endpoint and the
/// failure counter resets.
///
/// State is per-instance — no static fields — so two resolver instances
/// (e.g. test harness alongside production) cannot race for the same
/// rotation state. Matches the V2 invariant that all chain-service
/// runtime state lives on the service instance.
class RoundRobinElectrumEndpointResolver implements ElectrumEndpointResolver {
  RoundRobinElectrumEndpointResolver({
    Map<ChainId, List<String>>? endpointsByChain,
    this.failureThreshold = 2,
  }) : _endpoints = endpointsByChain ?? _defaultMainnetEndpoints;

  /// Per-chain ordered fallback list. First entry is the preferred
  /// endpoint. Order MAY be reshuffled on the fly by [reportSuccess].
  final Map<ChainId, List<String>> _endpoints;

  /// Number of consecutive failures before rotating off the current
  /// endpoint. `2` matches legacy BDK threshold; LWK legacy used `1`.
  final int failureThreshold;

  final Map<ChainId, int> _cursor = {};
  final Map<ChainId, int> _failures = {};

  /// Public for tests / diagnostics screens. Returns a defensive copy.
  Map<ChainId, List<String>> get endpointsByChain =>
      {for (final e in _endpoints.entries) e.key: List.unmodifiable(e.value)};

  @override
  String current(ChainId chain) {
    final list = _endpoints[chain];
    if (list == null || list.isEmpty) {
      throw StateError(
          'ElectrumEndpointResolver: no endpoints configured for $chain');
    }
    final i = _cursor[chain] ?? 0;
    return list[i % list.length];
  }

  @override
  void reportFailure(ChainId chain, Object _) {
    final next = (_failures[chain] ?? 0) + 1;
    _failures[chain] = next;
    if (next >= failureThreshold) {
      // Rotate to next endpoint. Reset failure counter so the new
      // endpoint gets its own quota before the next rotation.
      final list = _endpoints[chain];
      if (list != null && list.length > 1) {
        _cursor[chain] = ((_cursor[chain] ?? 0) + 1) % list.length;
      }
      _failures[chain] = 0;
    }
  }

  @override
  void reportSuccess(ChainId chain) {
    _failures[chain] = 0;
  }

  /// Mainnet fallback lists. Mirrors legacy BDK/LWK rotation order.
  static const Map<ChainId, List<String>> _defaultMainnetEndpoints = {
    ChainId.liquid: [
      'blockstream.info:995',
      'electrs.blockstream.info:995',
      'liquid.network:995',
      'les.bullbitcoin.com:995',
    ],
    ChainId.bitcoin: [
      'ssl://electrum.blockstream.info:50002',
      'ssl://btc.aftrek.org:50002',
      'ssl://fulcrum.sethforprivacy.com:50002',
      'ssl://electrum.bitaroo.net:50002',
    ],
  };
}
