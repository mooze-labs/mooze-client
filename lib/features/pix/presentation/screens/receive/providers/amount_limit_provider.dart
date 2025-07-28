import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';

final amountLimitProvider = FutureProvider<double>((ref) async {
  final userData = await ref.read(userDataProvider.future);

  return userData.fold((l) => 500.0, (user) {
    if (user.verificationLevel == 0) return 500.0;
    if (user.verificationLevel == 1) return 1000.0;

    return 5000.0;
  });
});
