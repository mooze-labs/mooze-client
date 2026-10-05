import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart'
    show CpfValidationErrorDto;
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/cpf_cnpj_input_formatter.dart';
import 'package:mooze_mobile/infra/core/core_sync_helpers.dart';

import '../../../../shared/fake_core_sync_helpers.dart';

class _MockHelpers extends Mock implements CoreSyncHelpers {}

/// The tax id rules run in mooze-core. These tests pin the Dart side: the
/// calls reach the core helpers and the results map to the app enum.
void main() {
  final helpers = _MockHelpers();
  useCoreSyncHelpers(helpers);
  tearDown(() => reset(helpers));

  group('CpfValidator.validate', () {
    test('returns null when the core accepts the input', () {
      when(() => helpers.taxIdValidate('529.982.247-25')).thenReturn(null);
      expect(CpfValidator.validate('529.982.247-25'), isNull);
    });

    test('maps every core error to the app enum', () {
      const cases = {
        CpfValidationErrorDto.empty: CpfValidationError.empty,
        CpfValidationErrorDto.incomplete: CpfValidationError.incomplete,
        CpfValidationErrorDto.invalid: CpfValidationError.invalid,
      };
      for (final entry in cases.entries) {
        when(() => helpers.taxIdValidate('x')).thenReturn(entry.key);
        expect(CpfValidator.validate('x'), entry.value);
      }
    });
  });

  test('strip, isValid and formatCpfCnpj delegate to the core', () {
    when(() => helpers.taxIdStrip('529.982.247-25')).thenReturn('52998224725');
    when(() => helpers.taxIdIsValid('11222333000181')).thenReturn(true);
    when(() => helpers.taxIdFormat('52998224725'))
        .thenReturn('529.982.247-25');

    expect(CpfValidator.strip('529.982.247-25'), '52998224725');
    expect(CpfValidator.isValid('11222333000181'), isTrue);
    expect(formatCpfCnpj('52998224725'), '529.982.247-25');
  });

  test('CpfCnpjInputFormatter applies the core mask and moves the cursor', () {
    when(() => helpers.taxIdMaskInput('5299822')).thenReturn('529.982.2');

    final result = CpfCnpjInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '5299822'),
    );

    expect(result.text, '529.982.2');
    expect(result.selection, const TextSelection.collapsed(offset: 9));
  });
}
