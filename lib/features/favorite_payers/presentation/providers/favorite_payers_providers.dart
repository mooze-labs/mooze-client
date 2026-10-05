import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/favorite_payers/data/repositories/core_favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';

final favoritePayersRepositoryProvider = Provider<FavoritePayersRepository>(
  (ref) => CoreFavoritePayersRepository(ref.watch(moozeCoreProvider.future)),
);
