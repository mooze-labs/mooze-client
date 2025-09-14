import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_text_styles.dart';

class TimerCountdown extends StatelessWidget {
  final DateTime expireAt;

  const TimerCountdown({super.key, required this.expireAt});

  @override
  Widget build(BuildContext context) {
    final Duration remainingTime = expireAt.difference(DateTime.now());
    final int minutes = remainingTime.inMinutes;
    final int seconds = remainingTime.inSeconds % 60;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTextStyles.subtitle,
        children: [
          TextSpan(
            text: "Você tem $minutes minutos e $seconds segundos",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(text: 'para concluir o pagamento'),
        ],
      ),
    );
  }
}
