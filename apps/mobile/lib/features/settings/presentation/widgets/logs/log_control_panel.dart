import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/domain/entities/logs_source.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_level_color_x.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Unified control surface for the logs screen.
///
/// One glass panel holds the overview, the search, the source selector, and
/// the level filters as rows split by hairlines. The level chips double as a
/// live category breakdown — each carries its current count — so statistics
/// and filtering share a single surface. A glass lens marks the selected
/// source and the selected level; the level color stays a small dot.
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
    final colors = context.colors;
    final tt = context.textTheme;
    final t = AppLocalizations.of(context);

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.logs_overview_title,
                        style: tt.titleSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.logs_overview_subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _TotalCount(count: totalCount, label: t.logs_entries_label),
              ],
            ),
          ),

          const PanelDivider(indent: 16),

          _SearchField(
            controller: searchController,
            hasQuery: searchQuery.isNotEmpty,
            hint: t.logs_filter_search_hint,
            onChanged: onSearchChanged,
            onClear: onClearSearch,
          ),

          const PanelDivider(indent: 16),

          _SectionLabel(text: t.logs_source_label),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _SourceSelector(
              source: source,
              onChanged: onSourceChanged,
              label: (s) => _sourceLabel(t, s),
            ),
          ),

          _SectionLabel(text: t.logs_levels_label),

          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              scrollDirection: Axis.horizontal,
              children: [
                _LevelChip(
                  label: t.logs_filter_all,
                  count: totalCount,
                  color: null,
                  selected: selectedLevel == null,
                  onTap: () => onLevelSelected(null),
                ),
                ...LogLevel.values.map(
                  (level) => _LevelChip(
                    label: level.displayName,
                    count: levelCounts[level] ?? 0,
                    color: level.color(context),
                    selected: selectedLevel == level,
                    onTap: () =>
                        onLevelSelected(selectedLevel == level ? null : level),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
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

/// Compact count of entries, shown on the right of the overview row.
class _TotalCount extends StatelessWidget {
  const _TotalCount({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _compactCount(count),
          style: tt.titleMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: tt.labelSmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

/// Search row of the panel: a borderless field on the glass.
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
    final colors = context.colors;
    final tt = context.textTheme;

    return TextField(
      controller: controller,
      style: tt.bodyMedium?.copyWith(color: colors.textPrimary),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: tt.bodyMedium?.copyWith(color: colors.textSecondary),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: colors.textSecondary,
        ),
        suffixIcon: hasQuery
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
                onPressed: onClear,
              )
            : null,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        constraints: const BoxConstraints(minHeight: 48),
      ),
    );
  }
}

/// Segmented choice of the log source. A glass lens slides under the
/// selected segment.
class _SourceSelector extends StatelessWidget {
  const _SourceSelector({
    required this.source,
    required this.onChanged,
    required this.label,
  });

  final LogSource source;
  final ValueChanged<LogSource> onChanged;
  final String Function(LogSource) label;

  static const double _height = 48;
  static const double _inset = 4;

  @override
  Widget build(BuildContext context) {
    final count = LogSource.values.length;
    final index = LogSource.values.indexOf(source);

    return SizedBox(
      height: _height,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: Motion.of(context, Motion.durationEmphasis),
              curve: Motion.curveMove,
              alignment: Alignment(-1 + 2 * index / (count - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                heightFactor: 1,
                child: const Padding(
                  padding: EdgeInsets.all(_inset),
                  child: GlassLens(),
                ),
              ),
            ),
          ),
          Row(
            children: LogSource.values.map((s) {
              return Expanded(
                child: _SourceSegment(
                  label: label(s),
                  selected: s == source,
                  onTap: () => onChanged(s),
                ),
              );
            }).toList(),
          ),
        ],
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
    final colors = context.colors;
    final tt = context.textTheme;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(
                color: selected ? colors.textPrimary : colors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Level filter with its live count. A glass lens marks the selected chip;
/// the level color shows only as a small dot.
class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;

  /// Level color of the dot. Null hides the dot (the "all" chip).
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tt = context.textTheme;
    final dotColor = color;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: Motion.of(context, Motion.durationFast),
                curve: Motion.curveMove,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: GlassLens(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dotColor != null) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    label,
                    style: tt.labelMedium?.copyWith(
                      color: selected
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _compactCount(count),
                    style: tt.labelSmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: context.textTheme.labelMedium?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String _compactCount(int v) {
  if (v < 1000) return v.toString();
  if (v < 1000000) return '${(v / 1000).toStringAsFixed(v < 10000 ? 1 : 0)}k';
  return '${(v / 1000000).toStringAsFixed(1)}M';
}
