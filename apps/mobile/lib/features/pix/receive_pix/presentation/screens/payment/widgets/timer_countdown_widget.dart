import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Time left to pay a Pix charge, as a quiet status line.
///
/// The line shows a clock and the time in `mm:ss`. Below
/// [urgentThreshold], the line changes to the warning tone. At zero, the
/// text changes to "expired". The text always carries the state, so the
/// state never depends on the color alone.
class TimerCountdown extends StatefulWidget {
  final DateTime expireAt;
  final VoidCallback? onExpired;

  const TimerCountdown({super.key, required this.expireAt, this.onExpired});

  /// Time left at which the line changes to the warning tone.
  static const urgentThreshold = Duration(minutes: 3);

  /// The clock of the countdown.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  @override
  State<TimerCountdown> createState() => _TimerCountdownState();
}

class _TimerCountdownState extends State<TimerCountdown> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    // A charge can open already expired, for example from the history. The
    // first read sets the time without setState, and a charge with no
    // time left needs no timer.
    _remainingTime = _timeLeft();
    if (_remainingTime == Duration.zero) {
      _expire();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  /// Time left to pay. Zero once the charge has expired.
  Duration _timeLeft() {
    final left = widget.expireAt.difference(TimerCountdown.clock());
    return left.isNegative || left.inSeconds == 0 ? Duration.zero : left;
  }

  void _tick() {
    if (!mounted) return;
    final left = _timeLeft();
    setState(() => _remainingTime = left);
    if (left == Duration.zero) {
      _timer?.cancel();
      _expire();
    }
  }

  /// Tells [TimerCountdown.onExpired], after the frame. It runs once: a
  /// charge that opens expired starts no timer, and the timer stops before
  /// it runs.
  void _expire() {
    final onExpired = widget.onExpired;
    if (onExpired == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) onExpired();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isExpired = _remainingTime == Duration.zero;
    final isUrgent = _remainingTime < TimerCountdown.urgentThreshold;
    final tone = isUrgent ? PixTone.warning : PixTone.neutral;
    final valueColor = pixToneColor(context, tone);
    final labelColor = isUrgent ? valueColor : context.colors.textSecondary;
    final minutes = _remainingTime.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    final style = context.textTheme.bodyMedium?.copyWith(color: labelColor);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixIcon(PixIcons.clock, size: 16, color: labelColor),
        const SizedBox(width: 8),
        Flexible(
          child: isExpired
              ? Text(
                  t.pix_deposit_expired,
                  style: style?.copyWith(fontWeight: FontWeight.w600),
                )
              : Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${t.pix_deposit_time_remaining} '),
                      TextSpan(
                        text: '$minutes:$seconds',
                        style: TextStyle(
                          color: valueColor,
                          fontWeight: FontWeight.w600,
                          // Tabular figures keep the line still while the
                          // digits change every second.
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  style: style,
                ),
        ),
      ],
    );
  }
}
