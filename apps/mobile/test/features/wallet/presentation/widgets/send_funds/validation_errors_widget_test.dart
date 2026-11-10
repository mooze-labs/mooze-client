import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/send_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/validation_errors_widget.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// A validation that stays at [initial].
class _FixedValidation extends SendValidationController {
  _FixedValidation(super.ref, SendValidationState initial) {
    state = initial;
  }
}

SendValidationError _error(
  SendValidationErrorCode code,
  SendValidationErrorCategory category,
) => SendValidationError(code: code, category: category);

final _addressRequired = _error(
  SendValidationErrorCode.addressRequired,
  SendValidationErrorCategory.address,
);
final _amountPositive = _error(
  SendValidationErrorCode.amountPositive,
  SendValidationErrorCategory.amount,
);
final _addressInvalid = _error(
  SendValidationErrorCode.addressInvalid,
  SendValidationErrorCategory.address,
);

Future<void> _pump(
  WidgetTester tester,
  List<SendValidationError> errors,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sendValidationControllerProvider.overrideWith(
          (ref) => _FixedValidation(ref, SendValidationState(errors: errors)),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            Theme(data: AppTheme.darkTheme(context), child: child!),
        home: const Scaffold(body: ValidationErrorsWidget()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  test('only an empty address and an empty amount are missing input', () {
    expect(
      [
        for (final code in SendValidationErrorCode.values)
          if (code.isMissingInput) code,
      ],
      [
        SendValidationErrorCode.addressRequired,
        SendValidationErrorCode.amountPositive,
      ],
    );
  });

  test('the shown errors leave out missing input', () {
    final state = SendValidationState(
      errors: [_addressRequired, _addressInvalid, _amountPositive],
    );

    expect(state.shownErrors, [_addressInvalid]);
    expect(state.errors, hasLength(3));
  });

  testWidgets('a new form, with no address and no amount, shows no error', (
    tester,
  ) async {
    await _pump(tester, [_addressRequired, _amountPositive]);

    expect(find.text(t.wallet_send_validation_attention), findsNothing);
    expect(find.text(t.wallet_send_error_address_required), findsNothing);
    expect(find.text(t.wallet_send_error_amount_positive), findsNothing);
  });

  testWidgets('an error about what the user entered shows, without the '
      'missing input', (tester) async {
    await _pump(tester, [_addressInvalid, _amountPositive]);

    expect(find.text(t.wallet_send_validation_attention), findsOneWidget);
    expect(find.text(t.wallet_send_error_address_invalid), findsOneWidget);
    expect(find.text(t.wallet_send_error_amount_positive), findsNothing);
  });
}
