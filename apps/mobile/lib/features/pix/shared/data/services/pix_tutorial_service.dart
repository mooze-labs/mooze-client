import 'package:mooze_core_bridge/mooze_core_bridge.dart';

/// PIX tutorial flag, stored in mooze-core.
class PixTutorialService {
  PixTutorialService(this._core);

  final Future<MoozeCore> _core;

  Future<bool> isTutorialShown() async =>
      (await _core).pixFlagIsSet(flag: PixFlagDto.tutorialShown);

  Future<void> setTutorialShown() async =>
      (await _core).pixFlagSet(flag: PixFlagDto.tutorialShown);

  Future<void> resetTutorial() async =>
      (await _core).pixFlagReset(flag: PixFlagDto.tutorialShown);
}
