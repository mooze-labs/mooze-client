import 'package:flutter/material.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';

/// Individual log item widget for log list
class LogItem extends StatelessWidget {
  final LogEntry log;
  final VoidCallback onTap;

  const LogItem({super.key, required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = _getColorForLevel(context, log.level);
    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:'
        '${log.timestamp.minute.toString().padLeft(2, '0')}:'
        '${log.timestamp.second.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.surfaceBright, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.outlineVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.level.displayName,
                          style: textTheme.labelSmall?.copyWith(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.tag,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.outlineVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.message,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForLevel(BuildContext context, LogLevel level) {
    final colorScheme = Theme.of(context).colorScheme;
    final extraColors = Theme.of(context).extension<AppExtraColors>();

    switch (level) {
      case LogLevel.debug:
        return colorScheme.outlineVariant;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return extraColors?.warning ?? Colors.orange;
      case LogLevel.error:
        return colorScheme.error;
      case LogLevel.critical:
        return Colors.purple;
    }
  }
}
