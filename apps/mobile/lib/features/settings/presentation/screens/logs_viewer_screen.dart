import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/domain/entities/logs_source.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_control_panel.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_item.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_detail_modal.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_page_scaffold.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/themes/motion.dart';
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

class _LogsViewerScreenState extends State<LogsViewerScreen>
    with SingleTickerProviderStateMixin {
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

  // Live level distribution for the control panel (source-dependent).
  Map<LogLevel, int> _levelCounts = const {};
  int _totalCount = 0;

  StreamSubscription<LogEntry>? _logStreamSubscription;
  Timer? _autoScrollDebounceTimer;
  Timer? _searchDebounceTimer;
  Timer? _statsDebounceTimer;

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      duration: Motion.durationEmphasis,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Motion.curveEnter,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Motion.curveEnter),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialLogs();
      _refreshStats();
    });

    _scrollController.addListener(_onScroll);

    _logStreamSubscription = widget.logger.logStream.listen((_) {
      if (!mounted) return;

      // Keep the distribution live without hammering the DB on every entry.
      _statsDebounceTimer?.cancel();
      _statsDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) _refreshStats();
      });

      if (_autoScroll && _logSource == LogSource.memory) {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start the entrance once; with reduced motion, show the page at rest.
    if (!_entryController.isAnimating && _entryController.value == 0) {
      if (Motion.isReduced(context)) {
        _entryController.value = 1;
      } else {
        _entryController.forward();
      }
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _logStreamSubscription?.cancel();
    _autoScrollDebounceTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _statsDebounceTimer?.cancel();
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

  /// Recomputes the per-level distribution shown in the control panel. Memory
  /// counts come straight from the ring buffer; database/all counts come from
  /// the persisted store's aggregate stats.
  Future<void> _refreshStats() async {
    if (!mounted) return;

    if (_logSource == LogSource.memory) {
      final counts = <LogLevel, int>{};
      for (final entry in widget.logger.logs) {
        counts[entry.level] = (counts[entry.level] ?? 0) + 1;
      }
      if (!mounted) return;
      setState(() {
        _levelCounts = counts;
        _totalCount = widget.logger.logs.length;
      });
      return;
    }

    final stats = await widget.logger.getDatabaseStats();
    if (!mounted) return;
    final byLevel = (stats['byLevel'] as Map?) ?? const {};
    final counts = <LogLevel, int>{
      for (final level in LogLevel.values)
        level: (byLevel[level.name] as int?) ?? 0,
    };
    setState(() {
      _levelCounts = counts;
      _totalCount = (stats['total'] as int?) ?? 0;
    });
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
          final page = start < filtered.length
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
              final timeA = a is LogEntry
                  ? a.timestamp
                  : (a as AppLog).timestamp;
              final timeB = b is LogEntry
                  ? b.timestamp
                  : (b as AppLog).timestamp;
              return timeB.compareTo(timeA);
            });

            _allLogs = merged.length > _pageSize
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
      stackTrace: appLog.stackTrace != null
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
    _refreshStats();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return SettingsPageScaffold(
      title: t.logs_viewer_title,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SettingsPageScaffold.gutter,
                  8,
                  SettingsPageScaffold.gutter,
                  0,
                ),
                child: LogControlPanel(
                  source: _logSource,
                  onSourceChanged: _onSourceChanged,
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: _onSearchChanged,
                  onClearSearch: _onClearSearch,
                  selectedLevel: _selectedLevel,
                  onLevelSelected: _onLevelSelected,
                  totalCount: _totalCount,
                  levelCounts: _levelCounts,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildBody(context, t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations t) {
    if (_isInitialLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            Text(
              t.logs_viewer_loading,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_allLogs.isEmpty) {
      return _EmptyState(message: t.logs_viewer_empty);
    }

    // Plain rows on the backdrop, split by hairlines. The transparent
    // Material gives the row ink a surface above the backdrop.
    return Material(
      type: MaterialType.transparency,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.only(
          bottom: 28 + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: _allLogs.length + (_hasMoreData ? 1 : 0),
        separatorBuilder: (context, index) => index < _allLogs.length - 1
            ? const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SettingsPageScaffold.gutter,
                ),
                child: PanelDivider(),
              )
            : const SizedBox.shrink(),
        itemBuilder: (context, index) {
          if (index == _allLogs.length) {
            return _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                : const SizedBox(height: 8);
          }

          final log = _toLogEntry(_allLogs[index]);
          return LogItem(
            log: log,
            onTap: () => LogDetailModal.show(context, log),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 32, color: colors.textSecondary),
          const SizedBox(height: 12),
          Text(
            message,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
