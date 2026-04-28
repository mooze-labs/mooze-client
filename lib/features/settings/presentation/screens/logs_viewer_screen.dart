import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/domain/entities/logs_source.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_filter_bar.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_item.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_detail_modal.dart';
import 'package:mooze_mobile/database/database.dart';

/// Screen for viewing and filtering application logs.
///
/// Filtering and search are pushed down to the data source (SQL for the
/// database, in-memory predicate for the ring buffer) so pagination and
/// search compose: the user sees matching rows from the very first page
/// without having to scroll-load the entire dataset first.
class LogsViewerScreen extends StatefulWidget {
  final AppLoggerService logger;

  const LogsViewerScreen({super.key, required this.logger});

  @override
  State<LogsViewerScreen> createState() => _LogsViewerScreenState();
}

class _LogsViewerScreenState extends State<LogsViewerScreen> {
  LogLevel? _selectedLevel;
  String _searchQuery = '';
  final bool _autoScroll = true;
  LogSource _logSource = LogSource.all;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  static const int _pageSize = 20;
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  // Holds the currently visible page set. Already filtered at the source.
  List<dynamic> _allLogs = [];
  bool _isInitialLoading = false;

  // Monotonic token: each load increments it; stale loads (older token)
  // discard their results so a fast typist can't get an out-of-order page.
  int _loadToken = 0;

  StreamSubscription<LogEntry>? _logStreamSubscription;
  Timer? _autoScrollDebounceTimer;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadInitialLogs();
    });

    _scrollController.addListener(_onScroll);

    _logStreamSubscription = widget.logger.logStream.listen((_) {
      if (_autoScroll && _logSource == LogSource.memory && mounted) {
        _loadInitialLogs();

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
    _searchDebounceTimer?.cancel();
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

  Future<void> _loadInitialLogs() async {
    if (!mounted) return;

    final token = ++_loadToken;

    setState(() {
      _isInitialLoading = true;
      _currentPage = 0;
      _hasMoreData = true;
      _allLogs.clear();
    });

    await _loadLogsPage(token);

    if (mounted && token == _loadToken) {
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    _currentPage++;
    await _loadLogsPage(_loadToken);

    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  /// Loads a page from the active source with the active filters applied
  /// at the source. The [token] is matched against [_loadToken] before
  /// committing results so superseded loads are discarded.
  Future<void> _loadLogsPage(int token) async {
    try {
      final offset = _currentPage * _pageSize;
      final level = _selectedLevel;
      final searchQuery = _searchQuery.isEmpty ? null : _searchQuery;

      switch (_logSource) {
        case LogSource.memory:
          final filtered = widget.logger.getMemoryLogsFiltered(
            level: level,
            searchQuery: searchQuery,
          );

          final start = offset;
          final end = (offset + _pageSize).clamp(0, filtered.length);
          final page =
              start < filtered.length
                  ? filtered.sublist(start, end)
                  : const <LogEntry>[];

          if (token != _loadToken) return;

          if (_currentPage == 0) {
            _allLogs = List<dynamic>.from(page);
          } else {
            _allLogs.addAll(page);
          }
          _hasMoreData = end < filtered.length;
          break;

        case LogSource.database:
          final dbLogs = await widget.logger.getLogsFromDatabasePaginated(
            limit: _pageSize,
            offset: offset,
            level: level,
            searchQuery: searchQuery,
          );

          if (token != _loadToken) return;

          if (_currentPage == 0) {
            _allLogs = List<dynamic>.from(dbLogs);
          } else {
            _allLogs.addAll(dbLogs);
          }
          _hasMoreData = dbLogs.length == _pageSize;
          break;

        case LogSource.all:
          if (_currentPage == 0) {
            // First page combines filtered memory (newest, full ring buffer)
            // with the first filtered DB page, then sorts by timestamp DESC.
            final memoryLogs = widget.logger.getMemoryLogsFiltered(
              level: level,
              searchQuery: searchQuery,
            );
            final dbLogs = await widget.logger.getLogsFromDatabasePaginated(
              limit: _pageSize,
              offset: 0,
              level: level,
              searchQuery: searchQuery,
            );

            if (token != _loadToken) return;

            final merged = <dynamic>[...memoryLogs, ...dbLogs];
            merged.sort((a, b) {
              final timeA =
                  a is LogEntry ? a.timestamp : (a as AppLog).timestamp;
              final timeB =
                  b is LogEntry ? b.timestamp : (b as AppLog).timestamp;
              return timeB.compareTo(timeA);
            });

            _allLogs =
                merged.length > _pageSize
                    ? merged.take(_pageSize).toList()
                    : merged;
            _hasMoreData =
                dbLogs.length == _pageSize || memoryLogs.length > _pageSize;
          } else {
            // Subsequent pages stream from the DB only — memory has already
            // been folded in on page 0.
            final dbLogs = await widget.logger.getLogsFromDatabasePaginated(
              limit: _pageSize,
              offset: _currentPage * _pageSize,
              level: level,
              searchQuery: searchQuery,
            );

            if (token != _loadToken) return;

            _allLogs.addAll(dbLogs);
            _hasMoreData = dbLogs.length == _pageSize;
          }
          break;
      }

      if (mounted && token == _loadToken) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading logs page: $e');
      if (mounted && token == _loadToken) {
        setState(() {
          _hasMoreData = false;
        });
      }
    }
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

  /// Convert AppLog (DB row) to LogEntry for the shared widget contract.
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

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    // Debounce: avoid hitting the DB on every keystroke.
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (mounted) _loadInitialLogs();
    });
  }

  void _onLevelSelected(LogLevel? level) {
    setState(() => _selectedLevel = level);
    _loadInitialLogs();
  }

  void _onClearSearch() {
    _searchController.clear();
    _searchDebounceTimer?.cancel();
    setState(() => _searchQuery = '');
    _loadInitialLogs();
  }

  void _onSourceChanged(LogSource source) {
    if (source == _logSource) return;
    setState(() => _logSource = source);
    _loadInitialLogs();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(elevation: 0, title: Text(t.logs_viewer_title)),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.onSurface.withValues(alpha: 0.12),
                ),
              ),
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
                                label: Text(_sourceLabel(t, source)),
                              ),
                            )
                            .toList(),
                    selected: {_logSource},
                    onSelectionChanged: (Set<LogSource> selected) {
                      _onSourceChanged(selected.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return colorScheme.primary;
                        }
                        return colorScheme.onSurface.withValues(alpha: 0.06);
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
            onSearchChanged: _onSearchChanged,
            onLevelSelected: _onLevelSelected,
            onClearSearch: _onClearSearch,
          ),
          Expanded(
            child:
                _isInitialLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            t.logs_viewer_loading,
                            style: textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _allLogs.isEmpty
                    ? Center(
                      child: Text(
                        t.logs_viewer_empty,
                        style: textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: _allLogs.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _allLogs.length) {
                          return _isLoadingMore
                              ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                              : const SizedBox.shrink();
                        }

                        final log = _toLogEntry(_allLogs[index]);
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
