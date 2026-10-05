import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/features/swap/domain/entities/peg.dart';
import 'package:mooze_mobile/features/swap/domain/usecases/peg_amount_validation.dart';
import 'package:mooze_mobile/infra/core/core_sync_helpers.dart';

import '../../../shared/fake_core_sync_helpers.dart';

class _MockHelpers extends Mock implements CoreSyncHelpers {}

/// The decision table runs in mooze-core (`pegValidateAmount`). These tests
/// pin the Dart side: the arguments reach the core and the result maps to
/// [PegAmountValidation].
void main() {
  setUpAll(() {
    registerFallbackValue(PegDirectionDto.pegIn);
    registerFallbackValue(BigInt.zero);
    registerFallbackValue(
      PegServerLimitsDto(
        minPegInSat: BigInt.zero,
        minPegOutSat: BigInt.zero,
        serverFeePercentPegIn: 0,
        serverFeePercentPegOut: 0,
      ),
    );
  });

  final helpers = _MockHelpers();
  useCoreSyncHelpers(helpers);
  tearDown(() => reset(helpers));

  const limits = PegServerLimits(
    minPegInSat: 10000,
    minPegOutSat: 25000,
    serverFeePercentPegIn: 0.1,
    serverFeePercentPegOut: 0.1,
  );

  void stub(PegAmountValidationDto result) {
    when(
      () => helpers.pegValidateAmount(
        direction: any(named: 'direction'),
        amountSat: any(named: 'amountSat'),
        spendableSat: any(named: 'spendableSat'),
        limits: any(named: 'limits'),
        fallbackMinimumSats: any(named: 'fallbackMinimumSats'),
        drain: any(named: 'drain'),
      ),
    ).thenReturn(result);
  }

  test('passes direction, amounts, limits and drain to the core', () {
    stub(
      PegAmountValidationDto(
        hasAmount: true,
        isValid: true,
        minimumSats: BigInt.from(25000),
        maximumSats: BigInt.from(90000),
        showsIssue: false,
      ),
    );

    final r = evaluatePegAmount(
      direction: PegDirection.pegOut,
      amountSat: BigInt.from(50000),
      spendableSat: BigInt.from(90000),
      limits: limits,
      fallbackMinimumSats: BigInt.from(25000),
      drain: true,
    );

    expect(r.isValid, isTrue);
    expect(r.issue, isNull);
    expect(r.minimumSats, BigInt.from(25000));
    expect(r.maximumSats, BigInt.from(90000));
    verify(
      () => helpers.pegValidateAmount(
        direction: PegDirectionDto.pegOut,
        amountSat: BigInt.from(50000),
        spendableSat: BigInt.from(90000),
        limits: PegServerLimitsDto(
          minPegInSat: BigInt.from(10000),
          minPegOutSat: BigInt.from(25000),
          serverFeePercentPegIn: 0.1,
          serverFeePercentPegOut: 0.1,
        ),
        fallbackMinimumSats: BigInt.from(25000),
        drain: true,
      ),
    ).called(1);
  });

  test('maps a core issue and shows it', () {
    stub(
      PegAmountValidationDto(
        hasAmount: true,
        isValid: false,
        issue: PegAmountIssueDto.belowMinimum,
        minimumSats: BigInt.from(10000),
        maximumSats: BigInt.from(200000),
        showsIssue: true,
      ),
    );

    final r = evaluatePegAmount(
      direction: PegDirection.pegIn,
      amountSat: BigInt.from(9999),
      spendableSat: BigInt.from(200000),
      limits: null,
      fallbackMinimumSats: BigInt.from(25000),
    );

    expect(r.isValid, isFalse);
    expect(r.issue, PegAmountIssue.belowMinimum);
    expect(r.showsIssue, isTrue);
  });

  test('no amount maps to the empty validation', () {
    stub(
      const PegAmountValidationDto(
        hasAmount: false,
        isValid: false,
        showsIssue: false,
      ),
    );

    final r = evaluatePegAmount(
      direction: PegDirection.pegIn,
      amountSat: null,
      spendableSat: BigInt.from(1000),
      limits: limits,
      fallbackMinimumSats: BigInt.from(25000),
    );

    expect(r.hasAmount, isFalse);
    expect(r.isValid, isFalse);
    expect(r.showsIssue, isFalse);
  });
}
