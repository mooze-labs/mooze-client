import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/buttons/secondary_button.dart';

const double buttonVerticalPadding = 16.0;
const double borderRadius = 8.0;
const double sectionTitleFontSize = 16.0;

class ReceiveButton extends StatelessWidget {
  const ReceiveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      text: "RECEBER",
      onPressed: () => context.push('/receive-asset'),
    );
  }
}

class SendButton extends StatelessWidget {
  const SendButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: "ENVIAR",
      onPressed: () => context.push("/send-asset"),
    );
  }
}
