import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/pin_theme.dart';
import 'package:pinput/pinput.dart';

class NewPinSetupScreen extends ConsumerStatefulWidget {
  final bool isChangingPin;

  const NewPinSetupScreen({super.key, this.isChangingPin = false});

  @override
  ConsumerState<NewPinSetupScreen> createState() => _NewPinSetupScreenState();
}

class _NewPinSetupScreenState extends ConsumerState<NewPinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool isPinValid = false;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(() {
      setState(() {
        isPinValid = _pinController.text.length == 6;
      });
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onContinuePressed() {
    final pin = _pinController.text;
    final t = AppLocalizations.of(context);

    if (pin.length < 6) {
      AppSnackBar.warning(context, t.pin_create_min_length);
      return;
    }

    context.push(
      '/setup/pin/confirm',
      extra: {'pin': pin, 'isChangingPin': widget.isChangingPin},
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.pin_create_title),
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineSmall,
                  children: [
                    TextSpan(text: t.pin_create_yours),
                    TextSpan(
                      text: t.pin_word,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge,
                  children: [
                    TextSpan(text: t.pin_create_intro_prefix),
                    TextSpan(
                      text: '${t.pin_word} ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: t.pin_create_intro_suffix),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 50),

              Pinput(
                keyboardType: TextInputType.number,
                length: 6,
                obscureText: true,
                controller: _pinController,
                focusNode: _focusNode,
                defaultPinTheme: PinThemes.focusedThemeOf(context),
              ),

              const SizedBox(height: 50),

              PrimaryButton(
                text: t.common_continue,
                onPressed: _onContinuePressed,
                isEnabled: isPinValid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
