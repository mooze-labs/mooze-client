import '../enums/address_chain.dart';

/// Heuristic chain detection for raw address strings.
///
/// Returns the candidate chains in priority order. When the prefix is
/// unambiguous (e.g. `bc1`, `lq1`), exactly one chain is returned. For
/// ambiguous or unknown prefixes the detector returns both, letting the
/// caller probe ownership against each.
class AddressChainDetector {
  const AddressChainDetector();

  /// Strips any payment-URI scheme (`bitcoin:`, `liquidnetwork:`,
  /// `liquidtestnet:`) and the optional query string. Returns the bare
  /// address.
  String stripUriScheme(String input) {
    final trimmed = input.trim();
    final colon = trimmed.indexOf(':');
    final raw = colon >= 0 ? trimmed.substring(colon + 1) : trimmed;
    final question = raw.indexOf('?');
    return question >= 0 ? raw.substring(0, question) : raw;
  }

  List<AddressChain> detect(String input) {
    final addr = stripUriScheme(input);
    if (addr.isEmpty) return const [];

    final lower = addr.toLowerCase();

    // Liquid bech32(m) human-readable parts.
    if (lower.startsWith('lq1') ||
        lower.startsWith('tlq1') ||
        lower.startsWith('ex1') ||
        lower.startsWith('tex1') ||
        lower.startsWith('el1') ||
        lower.startsWith('ert1')) {
      return const [AddressChain.liquid];
    }

    // Bitcoin bech32(m) human-readable parts.
    if (lower.startsWith('bc1') ||
        lower.startsWith('tb1') ||
        lower.startsWith('bcrt1')) {
      return const [AddressChain.bitcoin];
    }

    // Legacy / P2SH prefixes overlap between BTC and Liquid mainnet
    // (e.g. `H...` is Liquid P2SH, `3...` is Bitcoin P2SH; `Q...` is
    // Liquid P2PKH). Confidential legacy addresses on Liquid begin with
    // `VJL` (mainnet) or `vjT` (testnet).
    final first = addr[0];
    if (addr.startsWith('VJL') || addr.startsWith('vjT')) {
      return const [AddressChain.liquid];
    }
    if (first == 'Q' || first == 'H') {
      return const [AddressChain.liquid];
    }
    if (first == '1' || first == '3' ||
        first == 'm' || first == 'n' || first == '2') {
      return const [AddressChain.bitcoin];
    }

    // Unknown prefix — caller should probe both chains.
    return const [AddressChain.bitcoin, AddressChain.liquid];
  }
}
