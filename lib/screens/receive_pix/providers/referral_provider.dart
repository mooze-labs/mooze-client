import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/services/mooze/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'referral_provider.g.dart';

@riverpod
class ReferralCodeProvider extends _$ReferralCodeProvider {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    final referralCode = prefs.getString('referralCode');

    if (referralCode == null) {
      final userService = UserService(backendUrl: "api.mooze.app");
      final userDetails = await userService.getUserDetails();

      if (userDetails?.referredBy != null) {
        prefs.setString('referralCode', userDetails!.referredBy!);
        return true;
      }
    }

    return referralCode != null;
  }
}
