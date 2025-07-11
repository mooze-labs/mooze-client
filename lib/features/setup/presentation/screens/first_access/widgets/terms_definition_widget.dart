import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/setup/presentation/first_access/providers.dart';
import 'package:mooze_mobile/screens/settings/terms_and_conditions.dart';

class TermsDefinitionWidget extends ConsumerWidget {
  const TermsDefinitionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAccepted = ref.watch(termsAcceptanceProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: termsAccepted,
          onChanged: (value) {
            ref.read(termsAcceptanceProvider.notifier).state = !termsAccepted;
          },
          checkColor: Theme.of(context).colorScheme.onPrimary,
          activeColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(color: Theme.of(context).colorScheme.onPrimary),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Eu li e concordo com os ",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14.0,
                  ),
                ),
                TextSpan(
                  text: "Termos e Condições",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14.0,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TermsAndConditionsScreen(),
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
