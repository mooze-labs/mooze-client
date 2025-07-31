import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const double buttonVerticalPadding = 16.0;
const double borderRadius = 8.0;
const double sectionTitleFontSize = 16.0;

class ReceiveButton extends StatelessWidget {
  const ReceiveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.go("/wallet/receive"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
        padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius)
        )
      ),
      child: Text(
        "RECEBER",
        style: TextStyle(fontSize: sectionTitleFontSize, fontWeight: FontWeight.w600)
      )
    );
  }
}

class SendButton extends StatelessWidget {
  const SendButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () => context.go("/wallet/send"),
        style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius)
            )
        ),
        child: Text(
            "ENVIAR",
            style: TextStyle(fontSize: sectionTitleFontSize, fontWeight: FontWeight.w600)
        )
    );
  }
}
