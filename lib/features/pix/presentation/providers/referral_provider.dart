import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';

final hasReferralProvider = FutureProvider<bool>((ref) async {
  final userData = await ref.watch(userDataProvider.future);
  return userData.fold((l) => false, (user) => (user.referredBy != null));
});
