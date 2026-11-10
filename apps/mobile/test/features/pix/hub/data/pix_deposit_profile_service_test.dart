import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/shared/data/services/pix_deposit_profile_service.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_deposit_profile_service_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where older versions kept a copy of the deposit CPF.
const _legacyTaxIdKey = 'pix_deposit_tax_id';

void main() {
  late SharedPreferences prefs;
  late PixDepositProfileService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({_legacyTaxIdKey: '52998224725'});
    prefs = await SharedPreferences.getInstance();
    service = PixDepositProfileService(prefs);
  });

  test('starts without the acknowledgement', () {
    expect(service.hasAcknowledgedOwnershipNotice(), isFalse);
  });

  test('keeps the acknowledgement', () async {
    await service.acknowledgeOwnershipNotice();

    expect(service.hasAcknowledgedOwnershipNotice(), isTrue);
  });

  test('deletes the CPF copy of older versions', () async {
    await service.forgetLegacyTaxId();

    expect(prefs.containsKey(_legacyTaxIdKey), isFalse);
  });

  test('the first read of the service deletes the old CPF copy', () {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    container.read(pixDepositProfileServiceProvider);

    expect(prefs.containsKey(_legacyTaxIdKey), isFalse);
  });

  test('clear removes the acknowledgement and the old CPF copy', () async {
    await service.acknowledgeOwnershipNotice();

    await service.clear();

    expect(service.hasAcknowledgedOwnershipNotice(), isFalse);
    expect(prefs.containsKey(_legacyTaxIdKey), isFalse);
  });
}
