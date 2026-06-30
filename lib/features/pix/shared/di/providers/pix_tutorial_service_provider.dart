import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/data/services/pix_tutorial_service.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

final pixTutorialServiceProvider = Provider<PixTutorialService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PixTutorialService(prefs);
});
