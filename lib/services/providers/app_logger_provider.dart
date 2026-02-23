import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

final appLoggerProvider = Provider<AppLoggerService>((ref) {
  return AppLoggerService();
});
