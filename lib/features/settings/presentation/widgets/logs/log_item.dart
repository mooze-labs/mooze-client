import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_level_color_x.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// A single log entry rendered as a card row in the wallet's design language.
///
/// Layout mirrors the developer-screen cards: a rounded glyph keyed to the
/// log level, a metadata header (level badge · tag · timestamp), the message,
/// and — when present — a one-line error preview.
class LogItem extends StatelessWidget {
  final LogEntry log;
  final VoidCallback onTap;

  const LogItem({super.key, required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final extra = context.appColors;
    final tt = context.textTheme;
    final color = log.level.color(context);

    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:'
        '${log.timestamp.minute.toString().padLeft(2, '0')}:'
        '${log.timestamp.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LevelGlyph(level: log.level, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _LevelBadge(label: log.level.displayName, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              log.tag,
                              style: tt.bodySmall?.copyWith(
                                color: extra.textTertiary,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: tt.labelSmall?.copyWith(
                              color: extra.textTertiary,
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
                              color: cs.error.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                log.error.toString(),
                                style: tt.bodySmall?.copyWith(
                                  color: cs.error.withValues(alpha: 0.9),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelGlyph extends StatelessWidget {
  const _LevelGlyph({required this.level, required this.color});

  final LogLevel level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(level.icon, size: 17, color: color),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
