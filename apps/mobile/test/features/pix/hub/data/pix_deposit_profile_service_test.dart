import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/shared/data/services/pix_deposit_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PixDepositProfileService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = PixDepositProfileService(await SharedPreferences.getInstance());
  });

  test('starts without a CPF and without the acknowledgement', () {
    expect(service.taxIdNumber(), isNull);
    expect(service.hasTaxIdNumber(), isFalse);
    expect(service.hasAcknowledgedOwnershipNotice(), isFalse);
    expect(service.isReadyToDeposit(), isFalse);
  });

  test('keeps the CPF digits that were stored', () async {
    await service.saveTaxIdNumber('52998224725');

    expect(service.taxIdNumber(), '52998224725');
    expect(service.hasTaxIdNumber(), isTrue);
  });

  test('a stored CPF alone does not open the deposit flow', () async {
    await service.saveTaxIdNumber('52998224725');

    expect(service.isReadyToDeposit(), isFalse);
  });

  test('the acknowledgement alone does not open the deposit flow', () async {
    await service.acknowledgeOwnershipNotice();

    expect(service.isReadyToDeposit(), isFalse);
  });

  test('the deposit flow opens after both steps', () async {
    await service.saveTaxIdNumber('52998224725');
    await service.acknowledgeOwnershipNotice();

    expect(service.isReadyToDeposit(), isTrue);
  });

  test('clear removes both records', () async {
    await service.saveTaxIdNumber('52998224725');
    await service.acknowledgeOwnershipNotice();

    await service.clear();

    expect(service.taxIdNumber(), isNull);
    expect(service.hasAcknowledgedOwnershipNotice(), isFalse);
    expect(service.isReadyToDeposit(), isFalse);
  });
}
