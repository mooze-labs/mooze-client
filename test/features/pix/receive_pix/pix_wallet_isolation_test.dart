import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/pix/receive_pix/data/datasources/pix_deposit_db.dart';
import 'package:mooze_mobile/features/pix/receive_pix/data/repositories/pix_repository_impl.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../../shared/database_test_helpers.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);
}

ResponseBody _json(int status, Map<String, dynamic> body) {
  return ResponseBody.fromBytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Pix deposit cleanup (wallet-delete / import contract)', () {
    late AppDatabase db;

    setUp(() => db = buildInMemoryDatabase());
    tearDown(() async => db.close());

    test('clearAllDeposits wipes every deposit row', () async {
      final pixDb = PixDepositDatabase(db);
      await pixDb.addNewDeposit('dep-1', 'qr-1', Asset.depix.id, 1000).run();
      await pixDb.addNewDeposit('dep-2', 'qr-2', Asset.depix.id, 2000).run();

      final before = await pixDb.getDeposits().run();
      expect(before.getRight().toNullable(), hasLength(2));

      final cleared = await pixDb.clearAllDeposits().run();
      expect(cleared.isRight(), isTrue);

      final after = await pixDb.getDeposits().run();
      expect(after.getRight().toNullable(), isEmpty,
          reason: 'no previous-wallet deposit may survive cleanup');
    });

    test('a freshly cleared database surfaces no deposit by id', () async {
      final pixDb = PixDepositDatabase(db);
      await pixDb.addNewDeposit('dep-1', 'qr-1', Asset.depix.id, 1000).run();
      await pixDb.clearAllDeposits().run();

      final found = await pixDb.getDeposit('dep-1').run();
      expect(found.getRight().toNullable()!.isNone(), isTrue);
    });
  });

  group('PixRepositoryImpl disposal cancels background work', () {
    test(
        'newDeposit registers a polling timer; dispose cancels it and closes '
        'the status stream', () async {
      final db = buildInMemoryDatabase();
      addTearDown(db.close);

      final dio = Dio(BaseOptions(baseUrl: 'https://test'))
        ..httpClientAdapter = _StubAdapter((options) async {
          // POST /transactions → create a deposit.
          if (options.method == 'POST') {
            return _json(200, {
              'data': {
                'transaction_id': 'dep-1',
                'qr_copy_paste': 'qr-copy',
                'qr_image_url': 'https://img',
              },
            });
          }
          // GET status (would only fire after the 30s poll interval).
          return _json(200, {'data': []});
        });

      final repo = PixRepositoryImpl(dio, PixDepositDatabase(db));

      var streamClosed = false;
      final events = <dynamic>[];
      repo.statusUpdates.listen(events.add, onDone: () => streamClosed = true);

      final result =
          await repo.newDeposit(1000, 'liquid-address').run();
      expect(result.isRight(), isTrue,
          reason: 'deposit creation should succeed: '
              '${result.getLeft().toNullable()}');
      expect(repo.activePollTimers, 1,
          reason: 'a polling timer must be registered for the new deposit');

      repo.dispose();

      expect(repo.activePollTimers, 0,
          reason: 'dispose must cancel every polling timer');

      // Let the broadcast controller deliver the close.
      await Future<void>.delayed(Duration.zero);
      expect(streamClosed, isTrue,
          reason: 'dispose must close the status-update stream');
    });

    test('dispose is idempotent', () async {
      final db = buildInMemoryDatabase();
      addTearDown(db.close);
      final repo = PixRepositoryImpl(
        Dio(BaseOptions(baseUrl: 'https://test')),
        PixDepositDatabase(db),
      );

      repo.dispose();
      // A second dispose must not throw (no double-close of the controller).
      expect(repo.dispose, returnsNormally);
      expect(repo.activePollTimers, 0);
    });
  });
}
