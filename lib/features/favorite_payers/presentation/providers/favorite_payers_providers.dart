import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/favorite_payers/data/datasources/favorite_payers_local_datasource.dart';
import 'package:mooze_mobile/features/favorite_payers/data/repositories/favorite_payers_repository_impl.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/shared/infra/db/providers.dart';

final favoritePayersLocalDataSourceProvider =
    Provider<FavoritePayersLocalDataSource>(
      (ref) => FavoritePayersLocalDataSource(ref.watch(appDatabaseProvider)),
    );

final favoritePayersRepositoryProvider = Provider<FavoritePayersRepository>(
  (ref) =>
      FavoritePayersRepositoryImpl(ref.watch(favoritePayersLocalDataSourceProvider)),
);
