import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/features/pix/receive_pix/data/services/lbtc_warning_service.dart';
import 'package:mooze_mobile/features/pix/shared/data/services/pix_onboarding_service.dart';
import 'package:mooze_mobile/features/pix/shared/data/services/pix_tutorial_service.dart';

class _MockCore extends Mock implements MoozeCore {}

/// The PIX one-time flags live in mooze-core. Each service reads, sets and
/// resets its own flag.
void main() {
  setUpAll(() => registerFallbackValue(PixFlagDto.tutorialShown));

  late _MockCore core;
  final flags = <PixFlagDto>{};

  setUp(() {
    core = _MockCore();
    flags.clear();
    when(() => core.pixFlagIsSet(flag: any(named: 'flag'))).thenAnswer(
      (i) async => flags.contains(i.namedArguments[#flag] as PixFlagDto),
    );
    when(() => core.pixFlagSet(flag: any(named: 'flag'))).thenAnswer(
      (i) async => flags.add(i.namedArguments[#flag] as PixFlagDto),
    );
    when(() => core.pixFlagReset(flag: any(named: 'flag'))).thenAnswer(
      (i) async => flags.remove(i.namedArguments[#flag] as PixFlagDto),
    );
  });

  test('PixOnboardingService keeps the main and merchant flags apart',
      () async {
    final service = PixOnboardingService(Future.value(core));

    await service.markFirstTimeDialogAsSeen();

    expect(await service.hasSeenFirstTimeDialog(), isTrue);
    expect(await service.hasSeenMerchantFirstTimeDialog(), isFalse);
    expect(flags, {PixFlagDto.mainFirstTimeDialogShown});

    await service.markMerchantFirstTimeDialogAsSeen();
    await service.resetFirstTimeDialog();

    expect(flags, {PixFlagDto.merchantFirstTimeDialogShown});
    await service.resetMerchantFirstTimeDialog();
    expect(flags, isEmpty);
  });

  test('PixTutorialService uses the tutorial flag', () async {
    final service = PixTutorialService(Future.value(core));

    expect(await service.isTutorialShown(), isFalse);
    await service.setTutorialShown();
    expect(flags, {PixFlagDto.tutorialShown});
    await service.resetTutorial();
    expect(await service.isTutorialShown(), isFalse);
  });

  test('LbtcWarningService uses the L-BTC warning flag', () async {
    final service = LbtcWarningService(Future.value(core));

    await service.setWarningShown();
    expect(await service.isWarningShown(), isTrue);
    expect(flags, {PixFlagDto.lbtcWarningShown});
    await service.resetWarning();
    expect(flags, isEmpty);
  });
}
