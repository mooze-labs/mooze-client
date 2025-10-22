import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../entities.dart';

import 'user_service.dart';

class UserServiceImpl implements UserService {
  final Dio _dio;

  UserServiceImpl(Dio dio) : _dio = dio;

  @override
  TaskEither<String, User> getUser() {
    return TaskEither(() async {
      try {
        final response = await _dio.get('/users/me');

        final user = User.fromJson(response.data);

        return Right(user);
      } catch (e) {
        if (e is DioException) {
          // 404 user not found
        }
        return Left(e.toString());
      }
    });
  }

  @override
  TaskEither<String, Unit> addReferral(String referralCode) {
    return TaskEither(() async {
      try {
        await _dio.post(
          '/users/me/referral',
          data: {'referral_code': referralCode},
        );
        return const Right(unit);
      } catch (e) {
        return Left(e.toString());
      }
    });
  }
}
