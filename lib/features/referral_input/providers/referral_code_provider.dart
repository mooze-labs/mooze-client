import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'referral_code_provider.g.dart';

@riverpod
Future<String?> getReferralCode(Ref ref) async {
  final sharedPrefs = await SharedPreferences.getInstance();
  final referralCode = sharedPrefs.getString('referralCode');

  if (referralCode == null) {
    final userService = ref.read(userServiceProvider);
    final userResult = await userService.getUser().run();

    return userResult.match((error) => null, (user) {
      if (user.referredBy != null) {
        sharedPrefs.setString('referralCode', user.referredBy!);
        return user.referredBy;
      }
      return null;
    });
  }

  return referralCode;
}
