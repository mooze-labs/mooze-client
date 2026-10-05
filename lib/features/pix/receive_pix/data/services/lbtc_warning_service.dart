import 'package:mooze_core_bridge/mooze_core_bridge.dart';

/// L-BTC price fluctuation warning flag, stored in mooze-core.
class LbtcWarningService {
  LbtcWarningService(this._core);

  final Future<MoozeCore> _core;

  Future<bool> isWarningShown() async =>
      (await _core).pixFlagIsSet(flag: PixFlagDto.lbtcWarningShown);

  Future<void> setWarningShown() async =>
      (await _core).pixFlagSet(flag: PixFlagDto.lbtcWarningShown);

  Future<void> resetWarning() async =>
      (await _core).pixFlagReset(flag: PixFlagDto.lbtcWarningShown);
}
