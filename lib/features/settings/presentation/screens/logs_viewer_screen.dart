import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/payment/consts.dart'
    as AppColors;
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/log_filter_bar.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/log_item.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/log_detail_modal.dart';
import 'package:mooze_mobile/database/database.dart';

/// Source of logs to display
enum LogSource {
  memory('Memória'),
  database('Banco de Dados'),
  all('Todos');

  final String label;
  const LogSource(this.label);
}

/// Screen for viewing and filtering application logs
class LogsViewerScreen extends StatefulWidget {
  final AppLoggerService logger;

  const LogsViewerScreen({super.key, required this.logger});

  @override
  State<LogsViewerScreen> createState() => _LogsViewerScreenState();
}

class _LogsViewerScreenState extends State<LogsViewerScreen> {
  LogLevel? _selectedLevel;
  String _searchQuery = '';
  bool _autoScroll = true;
  LogSource _logSource = LogSource.all;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Combined logs from memory and database
  List<dynamic> _allLogs = [];
  bool _isLoadingDbLogs = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();

    // Auto-scroll to bottom when new logs arrive
    widget.logger.logStream.listen((_) {
      if (_autoScroll && mounted) {
        _loadLogs();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Load logs based on selected source
  Future<void> _loadLogs() async {
    setState(() => _isLoadingDbLogs = true);

    try {
      final memoryLogs = widget.logger.logs;
      final dbLogs = await widget.logger.getLogsFromDatabase();

      setState(() {
        switch (_logSource) {
          case LogSource.memory:
            _allLogs = memoryLogs;
            break;
          case LogSource.database:
            _allLogs = dbLogs;
            break;
          case LogSource.all:
            // Combine and sort by timestamp
            _allLogs = [...memoryLogs, ...dbLogs];
            _allLogs.sort((a, b) {
              final timeA =
                  a is LogEntry ? a.timestamp : (a as AppLog).timestamp;
              final timeB =
                  b is LogEntry ? b.timestamp : (b as AppLog).timestamp;
              return timeA.compareTo(timeB);
            });
            break;
        }
      });
    } catch (e) {
      debugPrint('Error loading logs: $e');
    } finally {
      setState(() => _isLoadingDbLogs = false);
    }
  }

  List<dynamic> _getFilteredLogs() {
    var logs = _allLogs;

    // Filter by level
    if (_selectedLevel != null) {
      logs =
          logs.where((log) {
            final level =
                log is LogEntry
                    ? log.level
                    : LogLevel.values.firstWhere(
                      (l) => l.name == (log as AppLog).level,
                      orElse: () => LogLevel.info,
                    );
            return level == _selectedLevel;
          }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      logs =
          logs.where((log) {
            final message =
                log is LogEntry ? log.message : (log as AppLog).message;
            final tag = log is LogEntry ? log.tag : (log as AppLog).tag;
            return message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                tag.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
    }

    return logs;
  }

  /// Convert AppLog to LogEntry for display
  LogEntry _toLogEntry(dynamic log) {
    if (log is LogEntry) return log;

    final appLog = log as AppLog;
    return LogEntry(
      timestamp: appLog.timestamp,
      level: LogLevel.values.firstWhere(
        (l) => l.name == appLog.level,
        orElse: () => LogLevel.info,
      ),
      tag: appLog.tag,
      message: appLog.message,
      error: appLog.error,
      stackTrace:
          appLog.stackTrace != null
              ? StackTrace.fromString(appLog.stackTrace!)
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Application Logs',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        // actions: [
        //   IconButton(
        //     icon: Icon(
        //       _autoScroll ? Icons.vertical_align_bottom : Icons.swap_vert,
        //       color: _autoScroll ? AppColors.primaryColor : Colors.grey,
        //     ),
        //     tooltip: 'Auto-scroll',
        //     onPressed: () => setState(() => _autoScroll = !_autoScroll),
        //   ),
        // ],
      ),
      body: Column(
        children: [
          // Log source selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<LogSource>(
                    segments:
                        LogSource.values
                            .map(
                              (source) => ButtonSegment(
                                value: source,
                                label: Text(
                                  source.label,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                    selected: {_logSource},
                    onSelectionChanged: (Set<LogSource> selected) {
                      setState(() {
                        _logSource = selected.first;
                      });
                      _loadLogs();
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primaryColor;
                        }
                        return Colors.grey[800];
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          LogFilterBar(
            searchController: _searchController,
            searchQuery: _searchQuery,
            selectedLevel: _selectedLevel,
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            onLevelSelected: (level) => setState(() => _selectedLevel = level),
            onClearSearch: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          Expanded(
            child:
                _isLoadingDbLogs
                    ? const Center(child: CircularProgressIndicator())
                    : filteredLogs.isEmpty
                    ? const Center(
                      child: Text(
                        'No logs found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = _toLogEntry(filteredLogs[index]);
                        return LogItem(
                          log: log,
                          onTap: () => LogDetailModal.show(context, log),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
