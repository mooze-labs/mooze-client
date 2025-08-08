import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/services/mooze/update.dart';

final updateDataProvider = FutureProvider<UpdateData>((ref) async {
  final svc = UpdateService();
  return await svc.getUpdateData();
});

final hasUpdateProvider = FutureProvider<bool>((ref) async {
  final updateData = await ref.read(updateDataProvider.future);
  return (currentVersion != updateData.currentVersion);
});