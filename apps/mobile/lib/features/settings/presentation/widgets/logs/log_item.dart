import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_level_color_x.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// A single log entry rendered as a plain row on the screen backdrop.
///
/// The row has no card of its own: the list separates rows with hairlines.
/// The level shows as a small signal (a dot and a label in the level color),
/// followed by the tag and the timestamp, the message, and — when present —
/// a one-line error preview.
class LogItem extends StatelessWidget {
  final LogEntry log;
  final VoidCallback onTap;

  const LogItem({super.key, required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tt = context.textTheme;
    final color = log.level.color(context);

    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:'
        '${log.timestamp.minute.toString().padLeft(2, '0')}:'
        '${log.timestamp.second.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    log.level.displayName,
                    style: tt.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.tag,
                      style: tt.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: tt.labelSmall?.copyWith(
                      color: colors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                log.message,
                style: tt.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  height: 1.3,
                  letterSpacing: -0.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (log.error != null) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 13,
                      color: colors.errorColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        log.error.toString(),
                        style: tt.bodySmall?.copyWith(
                          color: colors.errorColor,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
