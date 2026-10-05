import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/pix/shared/data/services/pix_tutorial_service.dart';

final pixTutorialServiceProvider = Provider<PixTutorialService>((ref) {
  return PixTutorialService(ref.watch(moozeCoreProvider.future));
});
