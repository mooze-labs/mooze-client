import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/user/services/mock_user_service.dart';
import 'package:mooze_mobile/shared/user/services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return MockUserService();
});
