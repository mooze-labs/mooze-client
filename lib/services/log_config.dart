import 'package:mooze_mobile/services/app_logger_service.dart';

/// Application logging configuration
///
/// Defines which log levels should be saved to the database
/// and how long the logs should be kept
class LogConfig {
  /// Log levels that should be saved to the database
  /// By default, only WARNING, ERROR and CRITICAL are saved
  final Set<LogLevel> savedLevels;

  /// Number of days to keep logs in the database
  /// Logs older than this period will be automatically removed
  /// Default: 30 days
  final int retentionDays;

  /// If true, DEBUG logs are also saved to the database
  /// Useful during development, but may generate a lot of data
  /// Default: false
  final bool includeDebug;

  /// If true, INFO logs are also saved to the database
  /// Default: false
  final bool includeInfo;

  const LogConfig({
    Set<LogLevel>? savedLevels,
    this.retentionDays = 30,
    this.includeDebug = false,
    this.includeInfo = false,
  }) : savedLevels =
           savedLevels ??
           const {LogLevel.warning, LogLevel.error, LogLevel.critical};

  /// Default configuration for production
  /// Saves INFO, WARNING, ERROR and CRITICAL for 7 days
  static const LogConfig production = LogConfig(
    savedLevels: {
      LogLevel.info,
      LogLevel.warning,
      LogLevel.error,
      LogLevel.critical,
    },
    retentionDays: 7,
    includeDebug: false,
    includeInfo: true,
  );

  /// Development configuration
  /// Saves all log levels for 7 days
  static const LogConfig development = LogConfig(
    savedLevels: {
      LogLevel.debug,
      LogLevel.info,
      LogLevel.warning,
      LogLevel.error,
      LogLevel.critical,
    },
    retentionDays: 7,
    includeDebug: false,
    includeInfo: false,
  );

  /// Minimal configuration
  /// Saves only critical errors for 60 days
  static const LogConfig minimal = LogConfig(
    savedLevels: {LogLevel.critical},
    retentionDays: 60,
    includeDebug: false,
    includeInfo: false,
  );

  /// Checks whether a given log level should be saved to the database
  bool shouldSaveLevel(LogLevel level) {
    if (savedLevels.contains(level)) {
      return true;
    }

    // Additional checks for convenience flags
    if (level == LogLevel.debug && includeDebug) {
      return true;
    }

    if (level == LogLevel.info && includeInfo) {
      return true;
    }

    return false;
  }

  /// Returns the cutoff date for log cleanup
  /// Logs before this date should be removed
  DateTime get cutoffDate {
    return DateTime.now().subtract(Duration(days: retentionDays));
  }

  LogConfig copyWith({
    Set<LogLevel>? savedLevels,
    int? retentionDays,
    bool? includeDebug,
    bool? includeInfo,
  }) {
    return LogConfig(
      savedLevels: savedLevels ?? this.savedLevels,
      retentionDays: retentionDays ?? this.retentionDays,
      includeDebug: includeDebug ?? this.includeDebug,
      includeInfo: includeInfo ?? this.includeInfo,
    );
  }

  @override
  String toString() {
    return 'LogConfig('
        'savedLevels: $savedLevels, '
        'retentionDays: $retentionDays, '
        'includeDebug: $includeDebug, '
        'includeInfo: $includeInfo'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LogConfig &&
        other.savedLevels == savedLevels &&
        other.retentionDays == retentionDays &&
        other.includeDebug == includeDebug &&
        other.includeInfo == includeInfo;
  }

  @override
  int get hashCode {
    return savedLevels.hashCode ^
        retentionDays.hashCode ^
        includeDebug.hashCode ^
        includeInfo.hashCode;
  }
}
