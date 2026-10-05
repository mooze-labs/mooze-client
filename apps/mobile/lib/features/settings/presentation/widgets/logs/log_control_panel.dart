import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/domain/entities/logs_source.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_level_color_x.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Unified control surface for the logs screen.
///
/// Folds the source selector, search, and level filters into one card that
/// follows the developer-screen design language. The level chips double as a
/// live category breakdown — each carries its current count — so statistics
/// and filtering share a single, structured surface.
class LogControlPanel extends StatelessWidget {
  const LogControlPanel({
    super.key,
    required this.source,
    required this.onSourceChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.selectedLevel,
    required this.onLevelSelected,
    required this.totalCount,
    required this.levelCounts,
  });

  final LogSource source;
  final ValueChanged<LogSource> onSourceChanged;

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  final LogLevel? selectedLevel;
  final ValueChanged<LogLevel?> onLevelSelected;

  final int totalCount;
  final Map<LogLevel, int> levelCounts;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final extra = context.appColors;
    final tt = context.textTheme;
    final t = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.terminal_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.logs_overview_title,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.logs_overview_subtitle,
                            style: tt.bodySmall?.copyWith(
                              color: extra.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _TotalBadge(count: totalCount, label: t.logs_entries_label),
                  ],
                ),

                const SizedBox(height: 16),

                _SearchField(
                  controller: searchController,
                  hasQuery: searchQuery.isNotEmpty,
                  hint: t.logs_filter_search_hint,
                  onChanged: onSearchChanged,
                  onClear: onClearSearch,
                ),

                const SizedBox(height: 16),

                _SectionLabel(text: t.logs_source_label),

                const SizedBox(height: 8),

                _SourceSelector(
                  source: source,
                  onChanged: onSourceChanged,
                  label: (s) => _sourceLabel(t, s),
                ),

                const SizedBox(height: 16),

                _SectionLabel(text: t.logs_levels_label),

                const SizedBox(height: 10),
              ],
            ),
          ),

          SizedBox(
            height: 40,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              children: [
                _LevelChip(
                  label: t.logs_filter_all,
                  count: totalCount,
                  color: cs.primary,
                  selected: selectedLevel == null,
                  showDot: false,
                  onTap: () => onLevelSelected(null),
                ),

                const SizedBox(width: 8),

                ...LogLevel.values.expand(
                  (level) => [
                    _LevelChip(
                      label: level.displayName,
                      count: levelCounts[level] ?? 0,
                      color: level.color(context),
                      selected: selectedLevel == level,
                      showDot: true,
                      onTap:
                          () => onLevelSelected(
                            selectedLevel == level ? null : level,
                          ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

  String _sourceLabel(AppLocalizations t, LogSource source) {
    switch (source) {
      case LogSource.memory:
        return t.logs_source_memory;
      case LogSource.database:
        return t.logs_source_database;
      case LogSource.all:
        return t.logs_source_all;
    }
  }
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final extra = context.appColors;
    final tt = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _compact(count),
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: extra.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  static String _compact(int v) {
    if (v < 1000) return v.toString();
    if (v < 1000000) return '${(v / 1000).toStringAsFixed(v < 10000 ? 1 : 0)}k';
    return '${(v / 1000000).toStringAsFixed(1)}M';
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hasQuery,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasQuery;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final extra = context.appColors;
    final tt = context.textTheme;

    return TextField(
      controller: controller,
      style: tt.bodyMedium,
      onChanged: onChanged,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: tt.bodyMedium?.copyWith(color: extra.textTertiary),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: extra.textTertiary,
        ),
        suffixIcon:
            hasQuery
                ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: extra.textTertiary,
                  ),
                  onPressed: onClear,
                )
                : null,
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _SourceSelector extends StatelessWidget {
  const _SourceSelector({
    required this.source,
    required this.onChanged,
    required this.label,
  });

  final LogSource source;
  final ValueChanged<LogSource> onChanged;
  final String Function(LogSource) label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children:
            LogSource.values.map((s) {
              return Expanded(
                child: _SourceSegment(
                  label: label(s),
                  selected: s == source,
                  onTap: () => onChanged(s),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _SourceSegment extends StatelessWidget {
  const _SourceSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final extra = context.appColors;
    final tt = context.textTheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: selected ? cs.onPrimary : extra.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.showDot,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final extra = context.appColors;
    final tt = context.textTheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color:
                selected
                    ? color.withValues(alpha: 0.16)
                    : cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  selected
                      ? color.withValues(alpha: 0.55)
                      : cs.onSurface.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDot) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: tt.labelMedium?.copyWith(
                  color: selected ? cs.onSurface : extra.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? color.withValues(alpha: 0.20)
                          : cs.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _compact(count),
                  style: tt.labelSmall?.copyWith(
                    color: selected ? color : extra.textTertiary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _compact(int v) {
    if (v < 1000) return v.toString();
    if (v < 1000000) return '${(v / 1000).toStringAsFixed(v < 10000 ? 1 : 0)}k';
    return '${(v / 1000000).toStringAsFixed(1)}M';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final extra = context.appColors;
    final tt = context.textTheme;
    return Text(
      text.toUpperCase(),
      style: tt.bodySmall?.copyWith(
        color: extra.textTertiary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        fontSize: 10,
      ),
    );
  }
}
