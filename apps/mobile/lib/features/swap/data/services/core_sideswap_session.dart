import 'package:mooze_core_bridge/mooze_core_bridge.dart';

/// SideSwap API key of the app. Override it at build time with
/// `--dart-define=SIDESWAP_API_KEY=...`.
const String sideswapApiKey = String.fromEnvironment(
  'SIDESWAP_API_KEY',
  defaultValue:
      '5c85504bf60e13e0d58614cb9ed86cb2c163cfa402fb3a9e63cf76c7a7af46a1',
);

/// The single SideSwap connection of mooze-core.
///
/// Swaps and pegs share it. [connected] opens the connection when it is
/// closed. The core makes the call a no-op when the socket is open, so
/// every operation calls it first.
class CoreSideswapSession {
  CoreSideswapSession({
    required Future<MoozeCore> core,
    this.apiKey = sideswapApiKey,
    this.url,
  }) : _core = core {
    // Stops an unhandled-error report when the core fails before the first
    // call. Each call still sees the error when it awaits.
    _core.ignore();
  }

  final Future<MoozeCore> _core;
  final String apiKey;

  /// SideSwap endpoint. Null uses the core default.
  final String? url;

  /// The core, after the connection is open.
  Future<MoozeCore> connected() async {
    final core = await _core;
    await core.sideswapConnect(apiKey: apiKey, url: url);
    return core;
  }

  /// The core, without a connection check.
  Future<MoozeCore> get core => _core;
}
