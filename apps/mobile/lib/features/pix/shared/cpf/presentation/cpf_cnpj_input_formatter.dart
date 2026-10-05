import 'package:flutter/services.dart';
import 'package:mooze_mobile/infra/core/core_sync_helpers.dart';

/// Live mask that formats input as a CPF (up to 11 digits) or CNPJ (12 to 14
/// digits), capped at 14 digits. The mask rules run in mooze-core.
class CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = CoreSyncHelpers.instance.taxIdMaskInput(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
