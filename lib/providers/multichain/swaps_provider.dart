import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/database.dart';

// Database instance provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Provider for swaps history
final swapsHistoryProvider = FutureProvider<List<Swap>>((ref) async {
  final database = ref.read(databaseProvider);
  return database.getAllSwaps();
});
