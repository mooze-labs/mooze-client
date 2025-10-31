import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_text_styles.dart';

class TimerCountdown extends StatefulWidget {
  final DateTime expireAt;
  final VoidCallback? onExpired;

  const TimerCountdown({super.key, required this.expireAt, this.onExpired});

  @override
  State<TimerCountdown> createState() => _TimerCountdownState();
}

class _TimerCountdownState extends State<TimerCountdown> {
  late Timer _timer;
  Duration _remainingTime = Duration.zero;
  bool _hasExpired = false;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateRemainingTime();
      }
    });
  }

  void _updateRemainingTime() {
    final newRemainingTime = widget.expireAt.difference(DateTime.now());

    setState(() {
      if (newRemainingTime.isNegative || newRemainingTime.inSeconds == 0) {
        _remainingTime = Duration.zero;
        _timer.cancel();

        if (!_hasExpired && widget.onExpired != null) {
          _hasExpired = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onExpired!();
            }
          });
        }
      } else {
        _remainingTime = newRemainingTime;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int minutes = _remainingTime.inMinutes;
    final int seconds = _remainingTime.inSeconds % 60;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTextStyles.subtitle,
        children: [
          const TextSpan(text: 'Você tem '),
          TextSpan(
            text: "$minutes minutos e $seconds segundos ",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(text: 'para concluir o pagamento.'),
        ],
      ),
    );
  }
}
