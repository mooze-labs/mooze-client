import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/payment/consts.dart'
    as AppColors;
import 'package:mooze_mobile/services/app_logger_service.dart';

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
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search logs...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon:
                  searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: onClearSearch,
                      )
                      : null,
              filled: true,
              fillColor: const Color(0xFF1A1B1F),
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
                _buildLevelChip(null, 'All'),
                const SizedBox(width: 8),
                ...LogLevel.values.map((level) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildLevelChip(level, level.displayName),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChip(LogLevel? level, String label) {
    final isSelected = selectedLevel == level;
    final color =
        level != null ? _getColorForLevel(level) : AppColors.primaryColor;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[400],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => onLevelSelected(selected ? level : null),
      backgroundColor: const Color(0xFF1A1B1F),
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: Colors.white,
      side: BorderSide(color: isSelected ? color : Colors.grey[700]!),
    );
  }

  Color _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.purple;
    }
  }
}
