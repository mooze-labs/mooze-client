import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../entities.dart';
import 'user_service_provider.dart';

final userDataProvider = FutureProvider<Either<String, User>>((ref) async {
  final userService = ref.read(userServiceProvider);
  return userService.getUser().run();
});
