import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_payment_link_access_provider.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';

UserLevelsData _levels(int level) => UserLevelsData(
  spendingLevel: level,
  levelProgress: 0,
  allowedSpending: 500,
  dailySpending: 0,
  currentLevelMinLimit: 0,
  currentLevelMaxLimit: 500,
  absoluteMinLimit: 20,
  absoluteMaxLimit: 3000,
  remainingLimit: 5000,
);

void main() {
  /// Reads the lock once [levels] has answered.
  Future<bool> lockedFor(Future<UserLevelsData> Function() levels) async {
    final container = ProviderContainer(
      overrides: [levelsProvider.overrideWith((ref) => levels())],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      pixPaymentLinkLockedProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(levelsProvider.future).catchError((_) => _levels(0));
    return container.read(pixPaymentLinkLockedProvider);
  }

  test('payment links start at Silver: Bronze is locked', () async {
    expect(await lockedFor(() async => _levels(0)), isTrue);
  });

  test('Silver, Gold and Diamond are not locked', () async {
    for (final level in [1, 2, 3]) {
      expect(await lockedFor(() async => _levels(level)), isFalse);
    }
  });

  // Without the level the app cannot tell. The API then answers INELIGIBLE
  // to an account below Silver.
  test('nothing is locked while the levels load or after they fail', () async {
    final container = ProviderContainer(
      overrides: [
        levelsProvider.overrideWith(
          (ref) => Completer<UserLevelsData>().future,
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(pixPaymentLinkLockedProvider), isFalse);

    expect(
      await lockedFor(() async => throw Exception('levels unavailable')),
      isFalse,
    );
  });
}
