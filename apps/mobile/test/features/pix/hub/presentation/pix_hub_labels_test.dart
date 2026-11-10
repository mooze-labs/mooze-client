import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  group('the refusal of the Pix provider', () {
    test('a daily limit names the limit', () {
      final message = pixHubFailureMessage(
        t,
        const PixHubFailure(
          PixHubErrorCode.dailyLimitExceeded,
          limitInCents: 600000,
        ),
      );

      expect(message, contains(formatBrlCents(600000)));
      expect(message, contains('Nenhum valor saiu da sua carteira'));
    });

    test('a daily limit without the amount still explains the limit', () {
      final message = pixHubFailureMessage(
        t,
        const PixHubFailure(PixHubErrorCode.dailyLimitExceeded),
      );

      expect(message, contains('limite diário'));
      expect(message, isNot(contains('R\$')));
    });

    test('another refusal shows the reason of the provider', () {
      final message = pixHubFailureMessage(
        t,
        const PixHubFailure(
          PixHubErrorCode.providerRefused,
          providerReason: 'Invalid tax-number: 123.',
        ),
      );

      expect(message, contains('Invalid tax-number: 123.'));
    });

    test('a refusal without a reason keeps the general text', () {
      final message = pixHubFailureMessage(
        t,
        const PixHubFailure(PixHubErrorCode.providerRefused),
      );

      expect(message, t.pix_hub_failure_provider_refused);
    });
  });
}
