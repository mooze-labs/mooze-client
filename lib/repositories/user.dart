import 'package:mooze_mobile/models/user.dart';
import 'package:mooze_mobile/services/mooze/referral.dart';
import 'package:mooze_mobile/services/mooze/user.dart';

class UserRepository {
  final UserService _userService;
  final ReferralService _referralService;
  final String _nostrPubKey;

  UserRepository({
    required UserService userService,
    required ReferralService referralService,
    required String nostrPubKey,
  }) : _userService = userService,
       _referralService = referralService,
       _nostrPubKey = nostrPubKey;

  Future<void> updateReferral(String referralCode) async {
    try {
      await _referralService.saveReferralCode(referralCode);
      await _referralService.registerReferral(_nostrPubKey, referralCode);
    } catch (e) {
      throw Exception('Failed to set referral code: $e');
    }
  }

  Future<User?> getUserInfo() async {
    return await _userService.getUser(_nostrPubKey);
  }
}
