import 'dart:async';

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

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  // Combined logs from memory and database
  List<dynamic> _allLogs = [];
  bool _isInitialLoading = false;

  // Stream subscription and debounce timer
  StreamSubscription<LogEntry>? _logStreamSubscription;
  Timer? _autoScrollDebounceTimer;

  @override
  void initState() {
    super.initState();

    // Load logs after frame is built to avoid blocking navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialLogs();
      }
    });

    // Add scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);

    // Auto-scroll to bottom when new logs arrive (only in memory mode)
    _logStreamSubscription = widget.logger.logStream.listen((_) {
      if (_autoScroll && _logSource == LogSource.memory && mounted) {
        _loadInitialLogs();

        // Debounce auto-scroll to avoid too many scroll operations
        _autoScrollDebounceTimer?.cancel();
        _autoScrollDebounceTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
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
    _logStreamSubscription?.cancel();
    _autoScrollDebounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreLogs();
      }
    }
  }

  /// Load initial logs (first page)
  Future<void> _loadInitialLogs() async {
    if (!mounted) return;

    setState(() {
      _isInitialLoading = true;
      _currentPage = 0;
      _hasMoreData = true;
      _allLogs.clear();
    });

    await _loadLogsPage();

    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
  }

  /// Load more logs (next page)
  Future<void> _loadMoreLogs() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    _currentPage++;
    await _loadLogsPage();

    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  /// Load a page of logs based on selected source
  Future<void> _loadLogsPage() async {
    try {
      final offset = _currentPage * _pageSize;

      switch (_logSource) {
        case LogSource.memory:
          // Memory logs - already in reverse order
          final memoryLogs = widget.logger.logs.reversed.toList();
          if (_currentPage == 0) {
            _allLogs = memoryLogs.take(_pageSize).toList();
          } else {
            final start = offset;
            final end = (offset + _pageSize).clamp(0, memoryLogs.length);
            if (start < memoryLogs.length) {
              _allLogs.addAll(memoryLogs.sublist(start, end));
            } else {
              _hasMoreData = false;
            }
          }
          _hasMoreData = _allLogs.length < memoryLogs.length;
          break;

        case LogSource.database:
          // Database logs - ordered by timestamp DESC in query
          final dbLogs = await widget.logger.getLogsFromDatabasePaginated(
            limit: _pageSize,
            offset: offset,
          );

          if (_currentPage == 0) {
            _allLogs = dbLogs;
          } else {
            _allLogs.addAll(dbLogs);
          }
          _hasMoreData = dbLogs.length == _pageSize;
          break;

        case LogSource.all:
          // Combine both sources
          if (_currentPage == 0) {
            // First page: get memory logs + first page of DB logs
            final memoryLogs = widget.logger.logs.reversed.toList();
            final dbLogs = await widget.logger.getLogsFromDatabasePaginated(
              limit: _pageSize,
              offset: 0,
            );

            _allLogs = [...memoryLogs, ...dbLogs];
            _allLogs.sort((a, b) {
              final timeA =
                  a is LogEntry ? a.timestamp : (a as AppLog).timestamp;
              final timeB =
                  b is LogEntry ? b.timestamp : (b as AppLog).timestamp;
              // Sort descending (newest first)
              return timeB.compareTo(timeA);
            });

            // Limit to page size
            if (_allLogs.length > _pageSize) {
              _allLogs = _allLogs.take(_pageSize).toList();
            }
            _hasMoreData = true;
          } else {
            // Subsequent pages: only from database
            final dbLogs = await widget.logger.getLogsFromDatabasePaginated(
              limit: _pageSize,
              offset: (_currentPage * _pageSize) - widget.logger.logs.length,
            );

            _allLogs.addAll(dbLogs);
            _hasMoreData = dbLogs.length == _pageSize;
          }
          break;
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading logs page: $e');
      if (mounted) {
        setState(() {
          _hasMoreData = false;
        });
      }
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
                      _loadInitialLogs();
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
                _isInitialLoading
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Carregando logs...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : filteredLogs.isEmpty
                    ? const Center(
                      child: Text(
                        'No logs found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredLogs.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredLogs.length) {
                          // Loading indicator at the end
                          return _isLoadingMore
                              ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                              : const SizedBox.shrink();
                        }

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
