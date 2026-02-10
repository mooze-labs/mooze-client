import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/merchant_mode_service.dart';

final merchantModeServiceProvider = Provider<MerchantModeService>((ref) {
  return MerchantModeService();
});
