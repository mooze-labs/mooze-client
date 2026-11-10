import 'package:mooze_mobile/shared/analytics/events.dart';
import 'package:mooze_mobile/shared/analytics/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/services/auth.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/shared/diagnostics/boot_tracer.dart';
import 'package:mooze_mobile/shared/key_management/providers/has_pin_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_entry_view.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_screen_scaffold.dart';

import '../../../di/providers/pin_setup_repository_provider.dart';

class ConfirmPinSetupScreen extends ConsumerStatefulWidget {
  const ConfirmPinSetupScreen({
    super.key,
    required this.pin,
    this.isChangingPin = false,
  });
  final String pin;
  final bool isChangingPin;

  @override
  ConsumerState<ConfirmPinSetupScreen> createState() =>
      _ConfirmPinSetupScreenState();
}

class _ConfirmPinSetupScreenState extends ConsumerState<ConfirmPinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool isPinValid = false;

  /// Number of mismatched attempts. Each rise shakes the PIN dots.
  int _errorCount = 0;

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
    super.dispose();
  }

  void _onConfirmPressed() async {
    final t = AppLocalizations.of(context);
    final inputPin = _pinController.text;

    if (inputPin != widget.pin) {
      AppSnackBar.error(context, t.pin_mismatch);
      setState(() => _errorCount++);
      _pinController.clear();
      return;
    }

    final pinSetupRepository = ref.read(pinSetupRepositoryProvider);
    BootTracer.mark('pin_confirm.create.begin');
    final result = await pinSetupRepository.createPin(inputPin).run();
    BootTracer.mark('pin_confirm.create.end', {'ok': result.isRight()});

    result.match((failure) => AppSnackBar.error(context, failure.toString()), (
      _,
    ) async {
      if (!widget.isChangingPin) {
        final method = ref.read(analyticsSetupMethodProvider);
        if (method != null) {
          ref
              .read(analyticsProvider)
              .track(
                AnalyticsEvent('onboarding_completed', {'method': method}),
              );
          ref.read(analyticsSetupMethodProvider.notifier).state = null;
        }
      }
      // Invalidate hasPinProvider after PIN creation
      BootTracer.mark('pin_confirm.invalidate.has_pin');
      ref.invalidate(hasPinProvider);

      // Always clear the session after a PIN save so the next app open
      // requires the new PIN — whether this is initial setup or a change.
      // Without this, the old session allows bypassing PIN entry entirely.
      BootTracer.mark('pin_confirm.session_invalidate.begin');
      await AuthenticationService().invalidateSession();
      BootTracer.mark('pin_confirm.session_invalidate.end');

      if (!mounted) return;

      if (widget.isChangingPin) {
        context.pop();
      } else {
        // For new wallet setup, offer biometric opt-in if the device
        // supports it. Otherwise go straight to the loading screen.
        final biometricService = ref.read(biometricServiceProvider);
        final isAvailable = await biometricService.isAvailable().run();

        if (!mounted) return;

        if (isAvailable) {
          BootTracer.mark('pin_confirm.nav.biometric');
          context.go('/setup/biometric');
        } else {
          BootTracer.mark('pin_confirm.nav.import_loading');
          context.go('/setup/wallet-import-loading');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PinScreenScaffold(
      appBarTitle: t.pin_confirm_title,
      onBack: () => context.pop(),
      child: PinEntryView(
        controller: _pinController,
        errorCount: _errorCount,
        header: PinHeader(
          title: t.pin_confirm_yours,
          highlight: t.pin_word,
          subtitle:
              '${t.pin_confirm_instruction_1}${t.pin_confirm_instruction_2}'
              '${t.pin_confirm_instruction_3}',
        ),
        action: PrimaryButton(
          text: t.common_confirm,
          onPressed: _onConfirmPressed,
          isEnabled: isPinValid,
        ),
      ),
    );
  }
}
