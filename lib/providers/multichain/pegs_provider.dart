import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/database.dart';
import 'package:mooze_mobile/providers/multichain/swaps_provider.dart'; // Import to use databaseProvider

// Reuse database provider from swaps_provider.dart
// final databaseProvider = Provider<AppDatabase>((ref) {
//   return AppDatabase();
// });

// Provider for pegs history
final pegsHistoryProvider = FutureProvider<List<Peg>>((ref) async {
  final database = ref.read(databaseProvider);
  return database.getAllPegs();
});
