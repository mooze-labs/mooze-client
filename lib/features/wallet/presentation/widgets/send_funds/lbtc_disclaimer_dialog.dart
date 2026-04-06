import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// One-time disclaimer shown on the first access to the Send screen.
/// Informs users that L-BTC is required to pay network mining fees.
class LbtcDisclaimerDialog extends StatefulWidget {
  const LbtcDisclaimerDialog({super.key});

  @override
  State<LbtcDisclaimerDialog> createState() => _LbtcDisclaimerDialogState();

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LbtcDisclaimerDialog(),
    );
  }
}

class _LbtcDisclaimerDialogState extends State<LbtcDisclaimerDialog> {
  int _secondsRemaining = 7;
  Timer? _timer;
  TapGestureRecognizer? _swapRecognizer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Navigate to swap and close dialog when SWAP link is tapped
    _swapRecognizer =
        TapGestureRecognizer()..onTap = () => Navigator.of(context).pop(true);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _swapRecognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Como funciona o envio de ativos',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para enviar ativos (Bitcoin L2, DePIX ou USDT), você precisa manter um saldo de Bitcoin L2 na sua carteira.',
            style: textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            colorScheme,
            Icons.bolt,
            'Taxas de rede',
            'O saldo de Bitcoin L2 é usado para pagar as taxas dos mineradores da rede Liquid.',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            colorScheme,
            Icons.swap_horiz,
            'Como obter Bitcoin L2',
            'Use a função SWAP ou receba Bitcoin via Lightning ou Liquid.',
            highlightText: 'SWAP',
            highlightRecognizer: _swapRecognizer,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mantenha um pequeno saldo de Bitcoin L2 para garantir que suas transações sejam processadas.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                _secondsRemaining == 0
                    ? () => Navigator.of(context).pop(false)
                    : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              _secondsRemaining == 0
                  ? 'Entendi'
                  : 'Entendi ($_secondsRemaining)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    ColorScheme colorScheme,
    IconData icon,
    String title,
    String description, {
    String? highlightText,
    TapGestureRecognizer? highlightRecognizer,
  }) {
    final textTheme = Theme.of(context).textTheme;

    Widget descriptionWidget;
    if (highlightText != null && description.contains(highlightText)) {
      final parts = description.split(highlightText);
      descriptionWidget = RichText(
        text: TextSpan(
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
            height: 1.4,
          ),
          children: [
            TextSpan(text: parts[0]),
            TextSpan(
              text: highlightText,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              recognizer: highlightRecognizer,
            ),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      );
    } else {
      descriptionWidget = Text(
        description,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.8),
          height: 1.4,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              descriptionWidget,
            ],
          ),
        ),
      ],
    );
  }
}
