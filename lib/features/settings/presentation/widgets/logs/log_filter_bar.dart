import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_level_color_x.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Filter bar for log viewer with search and level filters
class LogFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final LogLevel? selectedLevel;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<LogLevel?> onLevelSelected;
  final VoidCallback onClearSearch;

  const LogFilterBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.selectedLevel,
    required this.onSearchChanged,
    required this.onLevelSelected,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final t = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            style: textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: t.logs_filter_search_hint,
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: context.colors.textTertiary,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: context.colors.textTertiary,
              ),
              suffixIcon:
                  searchQuery.isNotEmpty
                      ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: context.colors.textTertiary,
                        ),
                        onPressed: onClearSearch,
                      )
                      : null,
              filled: true,
              fillColor: colorScheme.onSurface.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLevelChip(context, null, t.logs_filter_all),
                const SizedBox(width: 8),
                ...LogLevel.values.map((level) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildLevelChip(context, level, level.displayName),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChip(BuildContext context, LogLevel? level, String label) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final isSelected = selectedLevel == level;
    final color = level != null ? level.color(context) : colorScheme.primary;

    return FilterChip(
      label: Text(
        label,
        style: textTheme.labelMedium?.copyWith(
          color:
              isSelected ? colorScheme.onSurface : context.colors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => onLevelSelected(selected ? level : null),
      backgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: colorScheme.onSurface,
      side: BorderSide(
        color:
            isSelected ? color : colorScheme.onSurface.withValues(alpha: 0.12),
      ),
    );
  }
}
