import 'package:flutter/material.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: searchController,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search logs...',
              hintStyle: TextStyle(color: colorScheme.outlineVariant),
              prefixIcon: Icon(Icons.search, color: colorScheme.outlineVariant),
              suffixIcon:
                  searchQuery.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear, color: colorScheme.outlineVariant),
                        onPressed: onClearSearch,
                      )
                      : null,
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          // Level filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLevelChip(context, null, 'All'),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedLevel == level;
    final color =
        level != null ? _getColorForLevel(context, level) : colorScheme.primary;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? colorScheme.onSurface : colorScheme.outlineVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => onLevelSelected(selected ? level : null),
      backgroundColor: colorScheme.surfaceContainerHigh,
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: colorScheme.onSurface,
      side: BorderSide(color: isSelected ? color : colorScheme.outline),
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
