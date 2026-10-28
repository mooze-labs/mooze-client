import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';

/// Builds the log sink of one Pix backend call, tagged with [key].
///
/// Each line goes to the app log, which Settings exports, as a warning so a
/// production build keeps it. A debug build also prints it to the console as
/// `[key] message`, so a search for [key] finds it.
void Function(String message) pixApiLogSink(Ref ref, String key) {
  final logger = ref.read(appLoggerProvider);
  return (message) {
    logger.warning(key, message);
    if (kDebugMode) debugPrint('[$key] $message');
  };
}
