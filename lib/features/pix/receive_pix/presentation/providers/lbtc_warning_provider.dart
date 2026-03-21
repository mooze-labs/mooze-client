import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/receive_pix/data/services/lbtc_warning_service.dart';

final lbtcWarningServiceProvider = Provider<LbtcWarningService>((ref) {
  return LbtcWarningService();
});
