import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/data/datasources/pix_deposit_db.dart';

import 'package:mooze_mobile/features/pix/domain/repositories.dart';
import 'package:mooze_mobile/features/pix/data/repositories/pix_repository_impl.dart';
import 'package:mooze_mobile/shared/infra/db/providers.dart';

import 'package:mooze_mobile/shared/network/providers.dart';

final pixRepositoryProvider = Provider<PixRepository>((ref) {
  final authenticatedDioClient = ref.read(authenticatedClientProvider);
  final pixDatabase = PixDepositDatabase(ref.read(appDatabaseProvider));

  return PixRepositoryImpl(authenticatedDioClient, pixDatabase);
});
