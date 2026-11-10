import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/pix_charge_payer.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/pix_cpf_config.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/cpf_input_screen.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/own_deposit_payer.dart';

class PixCpfGateResult {
  final bool cancelled;

  final String? taxIdNumber;

  const PixCpfGateResult.proceed(this.taxIdNumber) : cancelled = false;

  const PixCpfGateResult.cancelled() : cancelled = true, taxIdNumber = null;
}

class PixCpfGate {
  const PixCpfGate._();

  /// Gets the document of the [payer] of a charge.
  ///
  /// - [PixChargePayer.self]: the document of the favorite payer marked as
  ///   "my user", without a question. Without that payer, a sheet asks the
  ///   user to register and mark it, and the deposit does not start. No
  ///   other document fills an own deposit.
  /// - [PixChargePayer.someoneElse]: the step always asks, with an empty
  ///   field, so no document of the user reaches another person's charge.
  static Future<PixCpfGateResult> ensure(
    BuildContext context,
    WidgetRef ref, {
    required PixChargePayer payer,
  }) async {
    if (!ref.read(pixCpfRequiredProvider)) {
      return const PixCpfGateResult.proceed(null);
    }

    if (payer == PixChargePayer.self) {
      final own = await readOwnDepositPayer(ref);
      if (own != null) return PixCpfGateResult.proceed(own.cpf);
      if (context.mounted) await showOwnPayerRequiredSheet(context);
      return const PixCpfGateResult.cancelled();
    }

    final taxIdNumber = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const CpfInputScreen()));

    if (taxIdNumber == null || taxIdNumber.isEmpty) {
      return const PixCpfGateResult.cancelled();
    }
    return PixCpfGateResult.proceed(taxIdNumber);
  }
}
