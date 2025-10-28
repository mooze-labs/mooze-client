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
        return Left(e.toString());
      }
    });
  }

  @override
  TaskEither<String, bool> validateReferralCode(String referralCode) {
    return TaskEither(() async {
      try {
        final response = await _dio.get('/users/referral/$referralCode');

        if (response.statusCode == 200) {
          if (response.data is Map && response.data.containsKey('valid')) {
            return Right(response.data['valid'] as bool);
          }

          if (response.data is Map &&
              response.data.containsKey('data') &&
              response.data['data'] is Map &&
              response.data['data'].containsKey('valid')) {
            return Right(response.data['data']['valid'] as bool);
          }

          return const Right(true);
        }

        return const Right(false);
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 404) {
          return const Right(false);
        }
        return Left('Erro ao validar código de referral: $e');
      }
    });
  }

  @override
  TaskEither<String, Unit> addReferral(String referralCode) {
    return TaskEither(() async {
      try {
        final response = await _dio.post(
          '/users/me/referral',
          data: {'referral_code': referralCode},
        );

        return const Right(unit);
      } catch (e) {
        if (e is DioException) {
          if (e.response?.statusCode == 400) {
            return const Left('Código de referral inválido');
          } else if (e.response?.statusCode == 409) {
            return const Left('Código de referral já foi usado');
          }
        }
        return Left('Erro ao adicionar código de referral: $e');
      }
    });
  }
}
