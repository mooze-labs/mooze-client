import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/favorite_payers/data/datasources/own_payer_store.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

final ownPayerStoreProvider = Provider<OwnPayerStore>(
  (ref) => OwnPayerStore(ref.watch(sharedPreferencesProvider)),
);

/// Id of the favorite payer marked as "my user", or null.
///
/// One payer at most carries the mark: a new mark replaces the old one.
class OwnPayerController extends Notifier<int?> {
  OwnPayerStore get _store => ref.read(ownPayerStoreProvider);

  @override
  int? build() => _store.read();

  Future<void> mark(int id) async {
    await _store.write(id);
    state = id;
  }

  Future<void> unmark() async {
    await _store.clear();
    state = null;
  }
}

final ownPayerIdProvider = NotifierProvider<OwnPayerController, int?>(
  OwnPayerController.new,
);

/// [payers] with the payer whose id is [ownId] first. The others keep their
/// order.
List<FavoritePayer> ownPayerFirst(List<FavoritePayer> payers, int? ownId) {
  final index = payers.indexWhere((p) => p.id == ownId);
  if (ownId == null || index <= 0) return payers;
  return [payers[index], ...payers.take(index), ...payers.skip(index + 1)];
}

/// The favorite payers as every list shows them: the payer marked as "my
/// user" first, then the others in the order of the store.
final orderedFavoritePayersProvider = Provider<AsyncValue<List<FavoritePayer>>>(
  (ref) {
    final ownId = ref.watch(ownPayerIdProvider);
    return ref
        .watch(favoritePayersControllerProvider)
        .whenData((payers) => ownPayerFirst(payers, ownId));
  },
);

/// The favorite payer marked as "my user", with its current document, or
/// null when no payer carries the mark.
///
/// The deposit flow takes the payer document from it, and from nothing else.
/// A mark whose payer no longer exists reads as no mark, so the deposit asks
/// the user to mark a payer again.
final ownFavoritePayerProvider = FutureProvider<FavoritePayer?>((ref) async {
  final id = ref.watch(ownPayerIdProvider);
  if (id == null) return null;
  final payers = await ref.watch(favoritePayersControllerProvider.future);
  return payers.where((p) => p.id == id).firstOrNull;
});
