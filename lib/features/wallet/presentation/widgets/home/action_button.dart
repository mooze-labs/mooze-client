import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets.dart';

const double buttonVerticalPadding = 16.0;
const double borderRadius = 8.0;
const double sectionTitleFontSize = 16.0;

class ReceiveButton extends StatefulWidget {
  const ReceiveButton({super.key});

  @override
  State<ReceiveButton> createState() => _ReceiveButtonState();
}

class _ReceiveButtonState extends State<ReceiveButton> {
  bool _isLoading = false;

  Future<void> _handlePress(BuildContext context) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await context.push('/receive-asset');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      text: "RECEBER",
      onPressed: () => _handlePress(context),
      isEnabled: !_isLoading,
      isLoading: _isLoading,
    );
  }
}

class SendButton extends StatefulWidget {
  const SendButton({super.key});

  @override
  State<SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<SendButton> {
  bool _isLoading = false;

  Future<void> _handlePress(BuildContext context) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await context.push("/send-asset");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: "ENVIAR",
      onPressed: () => _handlePress(context),
      isEnabled: !_isLoading,
      isLoading: _isLoading,
    );
  }
}
