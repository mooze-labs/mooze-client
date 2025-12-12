import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../entities.dart';
import 'user_service.dart';
import 'user_level_storage_service.dart';

class UserServiceImpl implements UserService {
  final Dio _dio;
  final UserLevelStorageService _levelStorageService;

  final _levelChangeController = StreamController<LevelChange>.broadcast();

  Stream<LevelChange> get levelChanges => _levelChangeController.stream;

  UserServiceImpl(Dio dio, this._levelStorageService) : _dio = dio;

  @override
  TaskEither<String, User> getUser() {
    return TaskEither(() async {
      try {
        final response = await _dio.get('/users/me');
        final user = User.fromJson(response.data);

        await _detectLevelChange(user.verificationLevel);

        return Right(user);
      } catch (e) {
        return Left(e.toString());
      }
    });
  }

  Future<void> _detectLevelChange(int newLevel) async {
    final storedLevel = _levelStorageService.getStoredVerificationLevel();

    if (storedLevel == null) {
      await _levelStorageService.saveVerificationLevel(newLevel);
      return;
    }

    if (storedLevel != newLevel) {
      final levelChange = LevelChange(
        oldLevel: storedLevel,
        newLevel: newLevel,
      );

      _levelChangeController.add(levelChange);
      await _levelStorageService.saveVerificationLevel(newLevel);
    }
  }

  Future<void> clearStoredLevel() async {
    await _levelStorageService.clearVerificationLevel();
  }

  void dispose() {
    _levelChangeController.close();
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
        await _dio.post(
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
