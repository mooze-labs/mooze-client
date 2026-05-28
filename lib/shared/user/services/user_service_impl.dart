import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/exceptions/user_friendly_exception.dart';

import '../entities.dart';
import 'user_service.dart';
import 'user_level_storage_service.dart';

class UserServiceImpl implements UserService {
  final Dio _dio;
  final UserLevelStorageService _levelStorageService;

  final _levelChangeController = StreamController<LevelChange>.broadcast();


  static const Duration _userCacheTtl = Duration(seconds: 30);
  Future<Either<String, User>>? _inFlightUser;
  User? _cachedUser;
  DateTime? _cachedAt;

  Stream<LevelChange> get levelChanges => _levelChangeController.stream;

  UserServiceImpl(Dio dio, this._levelStorageService) : _dio = dio;

  @override
  TaskEither<String, User> getUser() {
    return TaskEither(() async {
      final cached = _cachedUser;
      final cachedAt = _cachedAt;
      if (cached != null &&
          cachedAt != null &&
          DateTime.now().difference(cachedAt) < _userCacheTtl) {
        return Right(cached);
      }

      final inFlight = _inFlightUser;
      if (inFlight != null) {
        return inFlight;
      }

      final pending = _fetchUser();
      _inFlightUser = pending;
      try {
        return await pending;
      } finally {
        _inFlightUser = null;
      }
    });
  }

  Future<Either<String, User>> _fetchUser() async {
    try {
      final response = await _dio.get('/users/me');
      final user = User.fromJson(response.data);
      _cachedUser = user;
      _cachedAt = DateTime.now();
      await _detectLevelChange(user.spendingLevel);
      return Right(user);
    } catch (e) {
      return Left(_friendlyMessage(e));
    }
  }


  void invalidateUserCache() {
    _cachedUser = null;
    _cachedAt = null;
  }

  String _friendlyMessage(Object error) {
    final friendly = UserFriendlyException.fromError(error);
    if (kDebugMode) {
      debugPrint(
        '[UserService] ${friendly.userMessage} | technical: ${friendly.technicalMessage}',
      );
    }
    return friendly.userMessage;
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
        return Left(_friendlyMessage(e));
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

        // referredBy changed server-side — force the next read to refetch.
        invalidateUserCache();

        return const Right(unit);
      } catch (e) {
        if (e is DioException) {
          if (e.response?.statusCode == 400) {
            return const Left('Código de referral inválido');
          } else if (e.response?.statusCode == 409) {
            return const Left('Código de referral já foi usado');
          }
        }
        return Left(_friendlyMessage(e));
      }
    });
  }
}
