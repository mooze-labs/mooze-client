import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/amount_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/drain_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/fee_speed_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/send_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/auto_validation_listener.dart';

/// Counts the checks of the form.
class _CountingValidation extends SendValidationController {
  _CountingValidation(super.ref);

  int runs = 0;

  @override
  Future<void> validateTransaction() async => runs++;
}

void main() {
  testWidgets('a new fee speed or custom rate checks the form again, so the '
      'balance check counts the new fee', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sendValidationControllerProvider.overrideWith(
            _CountingValidation.new,
          ),
          finalAmountProvider.overrideWithValue(10000),
          isDrainTransactionProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: AutoValidationListener(child: SizedBox()),
        ),
      ),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AutoValidationListener)),
    );
    final validation =
        container.read(sendValidationControllerProvider.notifier)
            as _CountingValidation;
    final first = validation.runs;

    container.read(feeSpeedProvider.notifier).state = FeeSpeed.fast;
    await tester.pump();
    container.read(customFeeRateProvider.notifier).state = 14;
    await tester.pump();
    container.read(customFeeRateProvider.notifier).state = 15;
    await tester.pump();

    expect(validation.runs, first + 3);
  });
}
