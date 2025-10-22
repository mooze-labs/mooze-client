import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/user/providers/user_info_provider.dart';

final amountLimitProvider = FutureProvider<double>((ref) async {
  final userInfoResult = await ref.read(userInfoProvider.future);

  return userInfoResult.fold(
    (error) {
      return 500.0; 
    },
    (user) {
      return user.allowedSpending;
    },
  );
});
