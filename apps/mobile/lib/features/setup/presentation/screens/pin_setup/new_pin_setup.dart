import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_entry_view.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_screen_scaffold.dart';

class NewPinSetupScreen extends ConsumerStatefulWidget {
  final bool isChangingPin;

  const NewPinSetupScreen({super.key, this.isChangingPin = false});

  @override
  ConsumerState<NewPinSetupScreen> createState() => _NewPinSetupScreenState();
}

class _NewPinSetupScreenState extends ConsumerState<NewPinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
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
    super.dispose();
  }

  void _onContinuePressed() {
    final pin = _pinController.text;
    final t = AppLocalizations.of(context);

    if (pin.length < 6) {
      AppSnackBar.warning(
        context,
        widget.isChangingPin
            ? t.pin_change_min_length
            : t.pin_create_min_length,
      );
      return;
    }

    final extra = {'pin': pin, 'isChangingPin': widget.isChangingPin};

    if (widget.isChangingPin) {
      context.pushReplacement('/setup/pin/confirm', extra: extra);
    } else {
      context.push('/setup/pin/confirm', extra: extra);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isChanging = widget.isChangingPin;

    final titleText = isChanging ? t.pin_change_title : t.pin_create_title;
    final yoursText = isChanging ? t.pin_change_yours : t.pin_create_yours;
    final introPrefix = isChanging
        ? t.pin_change_intro_prefix
        : t.pin_create_intro_prefix;
    final introSuffix = isChanging
        ? t.pin_change_intro_suffix
        : t.pin_create_intro_suffix;

    return PinScreenScaffold(
      appBarTitle: titleText,
      onBack: () => context.pop(),
      child: PinEntryView(
        controller: _pinController,
        header: PinHeader(
          title: yoursText,
          highlight: t.pin_word,
          subtitle: '$introPrefix${t.pin_word} $introSuffix',
        ),
        action: PrimaryButton(
          text: t.common_continue,
          onPressed: _onContinuePressed,
          isEnabled: isPinValid,
        ),
      ),
    );
  }
}
