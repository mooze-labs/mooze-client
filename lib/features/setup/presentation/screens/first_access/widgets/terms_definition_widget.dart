import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/terms_and_conditions.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import '../providers/terms_acceptance_provider.dart';

class TermsDefinitionWidget extends ConsumerWidget {
  const TermsDefinitionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAccepted = ref.watch(termsAcceptanceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCheckbox(ref, termsAccepted, colorScheme),
        Expanded(child: _buildRichText(context, colorScheme, bodyStyle)),
      ],
    );
  }

  Widget _buildCheckbox(
    WidgetRef ref,
    bool termsAccepted,
    ColorScheme colorScheme,
  ) {
    return Checkbox(
      value: termsAccepted,
      onChanged: (_) {
        ref.read(termsAcceptanceProvider.notifier).state = !termsAccepted;
      },
    );
  }

  Widget _buildRichText(
    BuildContext context,
    ColorScheme colorScheme,
    TextStyle? bodyStyle,
  ) {
    final t = AppLocalizations.of(context);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: t.first_access_terms_prefix, style: bodyStyle),
          TextSpan(
            text: t.first_access_terms_link,
            style: bodyStyle?.copyWith(color: colorScheme.primary),
            recognizer:
                TapGestureRecognizer()
                  ..onTap = () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsAndConditionsScreen(),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
