import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/swap_audit_repository_impl.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/swap_audit_repository.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';

/// Synchronous provider — exposes the [SwapAuditRepository] for any caller
/// that needs to record swap activity. The repository itself is a thin
/// wrapper around the drift database; it has no expensive setup, so we
/// don't need a FutureProvider.
final swapAuditRepositoryProvider = Provider<SwapAuditRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final logger = ref.watch(appLoggerProvider);
  return SwapAuditRepositoryImpl(db, logger);
});
