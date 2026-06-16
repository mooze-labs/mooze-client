import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/storage/secure_storage.dart';
import 'package:mutex/mutex.dart';

import '../models.dart';
import '../services.dart';

class SessionManagerServiceImpl implements SessionManagerService {
  SessionManagerServiceImpl({
    RemoteAuthenticationService? remoteAuthService,
    FlutterSecureStorage? secureStorage,
    Dio? dio,
  })  : _remoteAuthService = remoteAuthService,
        _secureStorage = secureStorage ?? SecureStorageProvider.instance,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: const String.fromEnvironment(
                  'BACKEND_API_URL',
                  defaultValue: 'https://api.mooze.app',
                ),
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 10),
              ),
            );

  static const _jwtKey = 'jwt';
  static const _refreshKey = 'refresh_token';

  final RemoteAuthenticationService? _remoteAuthService;
  final FlutterSecureStorage _secureStorage;
  final Dio _dio;

  final Mutex _storageMutex = Mutex();

  Session? _cachedSession;
  bool _cacheLoaded = false;

  Future<Either<String, Session>>? _inFlightGet;
  Future<Either<String, Session>>? _inFlightRefresh;
  String? _inFlightRefreshKey;
  Future<Either<String, Session>>? _inFlightCreate;

  int _generation = 0;

  @override
  TaskEither<String, Session> getSession() {
    return TaskEither(() {
      final pending = _inFlightGet;
      if (pending != null) return pending;
      final f = _resolveSession();
      _inFlightGet = f;
      return f.whenComplete(() => _inFlightGet = null);
    });
  }

  @override
  TaskEither<String, Session> refreshSession(Session session) {
    return TaskEither(() => _refreshWithRecovery(session));
  }

  @override
  TaskEither<String, Session> forceRefresh() {
    return TaskEither(() async {
      final stored = await _readSession();
      if (stored == null) return _createSingleFlight();
      return _refreshWithRecovery(stored);
    });
  }

  @override
  TaskEither<String, Unit> saveSession(Session session) {
    return TaskEither(() async {
      await _writeSession(session);
      return const Right(unit);
    });
  }

  @override
  TaskEither<String, Unit> deleteSession() {
    return TaskEither(() async {
      await _clearSession();
      return const Right(unit);
    });
  }

  Future<Either<String, Session>> _resolveSession() async {
    final stored = await _readSession();
    if (stored == null) return _createSingleFlight();

    final expired = stored.isExpired().getOrElse((_) => true);
    if (!expired) return Right(stored);

    return _refreshWithRecovery(stored);
  }

  Future<Either<String, Session>> _refreshWithRecovery(Session current) async {
    final refreshed = await _refreshSingleFlight(current);

    return refreshed.fold<Future<Either<String, Session>>>(
      (_) async {
        final reread = await _reReadSession();
        if (reread != null && !(reread.isExpired().getOrElse((_) => true))) {
          return Right<String, Session>(reread);
        }
        await _clearSession();
        return _createSingleFlight();
      },
      (s) async => Right<String, Session>(s),
    );
  }

  Future<Either<String, Session>> _refreshSingleFlight(Session current) async {
    final key = current.refreshToken;

    if (_inFlightRefresh != null && _inFlightRefreshKey == key) {
      return _inFlightRefresh!;
    }

    if (_inFlightRefresh != null) {
      final stale = _inFlightRefresh!;
      await stale;
      final reread = await _readSession();
      if (reread != null && !(reread.isExpired().getOrElse((_) => true))) {
        return Right<String, Session>(reread);
      }
      return _refreshSingleFlight(current);
    }

    final f = _doRefresh(current);
    _inFlightRefresh = f;
    _inFlightRefreshKey = key;
    try {
      return await f;
    } finally {
      _inFlightRefresh = null;
      _inFlightRefreshKey = null;
    }
  }

  Future<Either<String, Session>> _doRefresh(Session current) async {
    final gen = _generation;
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': current.refreshToken},
      );

      // Backend wraps some responses as { data: { ... } } and others flat —
      // mirror Session.fromJson so a successful refresh never falls through
      // to a needless challenge/sign exchange.
      final body = response.data;
      final Map envelope;
      if (body is Map && body['data'] is Map) {
        envelope = body['data'] as Map;
      } else if (body is Map) {
        envelope = body;
      } else {
        envelope = const {};
      }

      final newJwt = envelope['jwt'];
      if (newJwt is! String || newJwt.isEmpty) {
        return const Left('JWT_NULL_IN_REFRESH_RESPONSE');
      }

      final maybeNewRefresh = envelope['refresh_token'];
      final newSession = Session(
        jwt: newJwt,
        refreshToken: maybeNewRefresh is String && maybeNewRefresh.isNotEmpty
            ? maybeNewRefresh
            : current.refreshToken,
      );

      await _writeSession(newSession, generation: gen);
      return Right(newSession);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) return const Left('REFRESH_TOKEN_NOT_FOUND');
      if (status == 401) return const Left('REFRESH_TOKEN_UNAUTHORIZED');
      return Left(e.toString());
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, Session>> _createSingleFlight() {
    if (_remoteAuthService == null) {
      return Future.value(
        const Left('RemoteAuthService not configured to create new session'),
      );
    }

    final existing = _inFlightCreate;
    if (existing != null) return existing;

    final f = _doCreate();
    _inFlightCreate = f;
    return f.whenComplete(() => _inFlightCreate = null);
  }

  Future<Either<String, Session>> _doCreate() async {
    final gen = _generation;
    // A refresh that succeeded just now may have already persisted a valid
    // session — bypass the cache, which still holds the expired snapshot.
    final maybeAlreadyValid = await _reReadSession();
    if (maybeAlreadyValid != null &&
        !(maybeAlreadyValid.isExpired().getOrElse((_) => true))) {
      return Right(maybeAlreadyValid);
    }

    final challengeE = await _remoteAuthService!.requestLoginChallenge().run();
    if (challengeE.isLeft()) {
      return Left(challengeE.getLeft().getOrElse(() => 'unknown'));
    }
    final challenge = challengeE.getRight().toNullable()!;

    final sessionE = await _remoteAuthService.signChallenge(challenge).run();
    if (sessionE.isLeft()) {
      return Left(sessionE.getLeft().getOrElse(() => 'unknown'));
    }
    final session = sessionE.getRight().toNullable()!;

    await _writeSession(session, generation: gen);
    return Right(session);
  }

  Future<Session?> _readSession() {
    return _storageMutex.protect<Session?>(() async {
      if (_cacheLoaded) return _cachedSession;
      return _loadFromStorageLocked();
    });
  }

  /// Cache-bypassing read. Used after a refresh failure or before creating a
  /// new session — another instance may have written valid credentials since
  /// the cache was populated.
  Future<Session?> _reReadSession() {
    return _storageMutex.protect<Session?>(_loadFromStorageLocked);
  }

  Future<Session?> _loadFromStorageLocked() async {
    final jwt = await _secureStorage.read(key: _jwtKey);
    final rt = await _secureStorage.read(key: _refreshKey);
    _cacheLoaded = true;
    if (jwt == null || rt == null) {
      _cachedSession = null;
      return null;
    }
    _cachedSession = Session(jwt: jwt, refreshToken: rt);
    return _cachedSession;
  }

  Future<void> _writeSession(Session s, {int? generation}) {
    return _storageMutex.protect<void>(() async {
      if (generation != null && generation != _generation) {
        return;
      }
      await _secureStorage.write(key: _jwtKey, value: s.jwt);
      await _secureStorage.write(key: _refreshKey, value: s.refreshToken);
      _cachedSession = s;
      _cacheLoaded = true;
    });
  }

  Future<void> _clearSession() {
    return _storageMutex.protect<void>(() async {
      _generation++;
      await _secureStorage.delete(key: _jwtKey);
      await _secureStorage.delete(key: _refreshKey);
      _cachedSession = null;
      _cacheLoaded = false;
      _inFlightRefresh = null;
      _inFlightRefreshKey = null;
      _inFlightCreate = null;
    });
  }
}
