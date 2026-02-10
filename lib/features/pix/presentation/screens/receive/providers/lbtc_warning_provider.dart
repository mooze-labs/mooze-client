import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/lbtc_warning_service.dart';

final lbtcWarningServiceProvider = Provider<LbtcWarningService>((ref) {
  return LbtcWarningService();
});
