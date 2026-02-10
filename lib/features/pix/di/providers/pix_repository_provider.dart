import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/data/datasources/pix_deposit_db.dart';

import 'package:mooze_mobile/features/pix/domain/repositories.dart';
import 'package:mooze_mobile/features/pix/data/repositories/pix_repository_impl.dart';
import 'package:mooze_mobile/shared/infra/db/providers.dart';

import 'package:mooze_mobile/shared/network/providers.dart';
import 'package:mooze_mobile/shared/authentication/providers.dart';

final pixRepositoryProvider = Provider<PixRepository>((ref) {
  final authenticatedDioClient = ref.watch(authenticatedClientProvider);
  final pixDatabase = PixDepositDatabase(ref.watch(appDatabaseProvider));
  final sessionManager = ref.watch(sessionManagerServiceProvider);

  return PixRepositoryImpl(
    authenticatedDioClient,
    pixDatabase,
  ); // TODO: Session
});
