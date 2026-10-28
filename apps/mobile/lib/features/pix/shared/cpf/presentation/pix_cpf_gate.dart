import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/pix_cpf_config.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/cpf_input_screen.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_deposit_profile_service_provider.dart';

class PixCpfGateResult {
  final bool cancelled;

  final String? taxIdNumber;

  const PixCpfGateResult.proceed(this.taxIdNumber) : cancelled = false;

  const PixCpfGateResult.cancelled() : cancelled = true, taxIdNumber = null;
}

class PixCpfGate {
  const PixCpfGate._();

  static Future<PixCpfGateResult> ensure(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!ref.read(pixCpfRequiredProvider)) {
      return const PixCpfGateResult.proceed(null);
    }

    // The deposit gate already asked for the CPF, so the screen opens filled
    // and the user confirms it instead of typing it again.
    final storedTaxId = ref
        .read(pixDepositProfileServiceProvider)
        .taxIdNumber();

    final taxIdNumber = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CpfInputScreen(initialTaxId: storedTaxId),
      ),
    );

    if (taxIdNumber == null || taxIdNumber.isEmpty) {
      return const PixCpfGateResult.cancelled();
    }
    return PixCpfGateResult.proceed(taxIdNumber);
  }
}
