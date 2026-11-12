import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/merchant/presentation/controllers/merchant_validation_controller.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';

/// A Silver account that receives from R$ 20,00 to R$ 500,00 per Pix.
const _silver = UserLevelsData(
  spendingLevel: 1,
  levelProgress: 0,
  allowedSpending: 500,
  dailySpending: 0,
  currentLevelMinLimit: 0,
  currentLevelMaxLimit: 500,
  absoluteMinLimit: 20,
  absoluteMaxLimit: 3000,
  remainingLimit: 5000,
);

// The charge screen checks the sale amount before the merchant picks the
// QR Code or the payment link. Both then receive within the Pix receive
// limits of the account: the minimum and the limit per transaction.
void main() {
  Future<MerchantValidation> validate(double amount) async {
    final container = ProviderContainer(
      overrides: [levelsProvider.overrideWith((ref) async => _silver)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      merchantValidationProvider(amount),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(levelsProvider.future);
    return container.read(merchantValidationProvider(amount));
  }

  test('an amount within the Pix receive limits is valid', () async {
    expect((await validate(20)).isValid, isTrue);
    expect((await validate(500)).isValid, isTrue);
  });

  test('an amount above the limit per transaction is not valid', () async {
    final validation = await validate(500.01);
    expect(validation.isValid, isFalse);
    expect(validation.error, MerchantValidationError.aboveTransaction);
    expect(validation.amount, 500);
  });

  test('an amount below the minimum is not valid', () async {
    final validation = await validate(19.99);
    expect(validation.isValid, isFalse);
    expect(validation.error, MerchantValidationError.belowMinimum);
    expect(validation.amount, 20);
  });
}
