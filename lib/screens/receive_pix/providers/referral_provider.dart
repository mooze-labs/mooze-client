import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/mooze/user_provider.dart';
import 'package:mooze_mobile/services/mooze/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'referral_provider.g.dart';

@riverpod
Future<String?> getReferralCode(Ref ref) async {
  final sharedPrefs = await SharedPreferences.getInstance();
  final userRepository = ref.read(userRepositoryProvider);

  if (sharedPrefs.getString('referralCode') != null) {
    return sharedPrefs.getString('referralCode');
  }

  final user = await userRepository.value?.getUserInfo();
  return user?.referredBy;
}
