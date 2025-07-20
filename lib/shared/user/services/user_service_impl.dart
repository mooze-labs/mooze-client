import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../entities.dart';

import 'user_service.dart';

class UserServiceImpl implements UserService {
  final Dio _dio;
  final String _publicKey;

  UserServiceImpl(Dio dio, String publicKey)
    : _dio = dio,
      _publicKey = publicKey;

  @override
  TaskEither<String, User> getUser() {
    return TaskEither(() async {
      try {
        final response = await _dio.get('/user/$_publicKey');
        return Right(User.fromJson(response.data));
      } catch (e) {
        return Left(e.toString());
      }
    });
  }

  @override
  TaskEither<String, Unit> addReferral(String referralCode) {
    return TaskEither(() async {
      try {
        await _dio.post(
          '/user/$_publicKey/referral',
          data: {'code': referralCode},
        );
        return const Right(unit);
      } catch (e) {
        return Left(e.toString());
      }
    });
  }
}
