import 'package:mooze_core_bridge/mooze_core_bridge.dart';

/// First-time PIX dialog flags, stored in mooze-core.
class PixOnboardingService {
  PixOnboardingService(this._core);

  final Future<MoozeCore> _core;

  /// True if the user has already seen the main PIX first-time dialog.
  Future<bool> hasSeenFirstTimeDialog() =>
      _isSet(PixFlagDto.mainFirstTimeDialogShown);

  /// Marks the main PIX first-time dialog as seen and accepted.
  Future<void> markFirstTimeDialogAsSeen() =>
      _set(PixFlagDto.mainFirstTimeDialogShown);

  /// Clears the main PIX dialog flag.
  Future<void> resetFirstTimeDialog() =>
      _reset(PixFlagDto.mainFirstTimeDialogShown);

  /// True if the user has already seen the Merchant PIX first-time dialog.
  Future<bool> hasSeenMerchantFirstTimeDialog() =>
      _isSet(PixFlagDto.merchantFirstTimeDialogShown);

  /// Marks the Merchant PIX first-time dialog as seen and accepted.
  Future<void> markMerchantFirstTimeDialogAsSeen() =>
      _set(PixFlagDto.merchantFirstTimeDialogShown);

  /// Clears the Merchant dialog flag.
  Future<void> resetMerchantFirstTimeDialog() =>
      _reset(PixFlagDto.merchantFirstTimeDialogShown);

  Future<bool> _isSet(PixFlagDto flag) async =>
      (await _core).pixFlagIsSet(flag: flag);

  Future<void> _set(PixFlagDto flag) async =>
      (await _core).pixFlagSet(flag: flag);

  Future<void> _reset(PixFlagDto flag) async =>
      (await _core).pixFlagReset(flag: flag);
}
