import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:mooze_mobile/features/swap/data/datasources/sideswap.dart';
import 'package:mooze_mobile/utils/websocket.dart';

/// Correlation guarantees for the SideSwap JSON-RPC transport.
///
/// Before this, every request went out as `"id": 1` and the peg helpers
/// resolved from the *first* emission on a broadcast stream. Two peg
/// operations in flight meant one response completed both futures — an order
/// id could be attributed to the wrong operation. These tests pin the fix.
void main() {
  late _FakeTransport ws;
  late SideswapApi api;

  setUp(() {
    ws = _FakeTransport();
    api = SideswapApi(transport: ws);
  });

  tearDown(() {
    api.dispose();
  });

  group('request id allocation', () {
    test('each request carries a distinct id', () async {
      unawaited(
        api
            .request('peg', {'peg_in': true})
            .catchError((_) => <String, dynamic>{}),
      );
      unawaited(
        api
            .request('peg_status', {'order_id': 'x'})
            .catchError((_) => <String, dynamic>{}),
      );

      await pumpEventQueue();

      final ids = ws.sent.map((m) => jsonDecode(m)['id'] as int).toList();
      expect(ids, hasLength(2));
      expect(ids.toSet(), hasLength(2), reason: 'ids must not repeat');
    });

    test('sends the method and params verbatim', () async {
      unawaited(
        api
            .request('peg', {'peg_in': false, 'recv_addr': 'bc1q'})
            .catchError((_) => <String, dynamic>{}),
      );
      await pumpEventQueue();

      final msg = jsonDecode(ws.sent.single) as Map<String, dynamic>;
      expect(msg['method'], 'peg');
      expect(msg['params'], {'peg_in': false, 'recv_addr': 'bc1q'});
    });
  });

  group('response correlation', () {
    test('out-of-order responses resolve their own requests', () async {
      // The exact scenario the old code got wrong: A is sent first, B second,
      // and B answers first.
      final a = api.request('peg', {'peg_in': true});
      final b = api.request('peg_status', {'order_id': 'B'});
      await pumpEventQueue();

      final idA = jsonDecode(ws.sent[0])['id'] as int;
      final idB = jsonDecode(ws.sent[1])['id'] as int;

      ws.inject({
        'id': idB,
        'method': 'peg_status',
        'result': {'order_id': 'B'},
      });
      ws.inject({
        'id': idA,
        'method': 'peg',
        'result': {'order_id': 'A'},
      });

      expect((await a)['order_id'], 'A');
      expect((await b)['order_id'], 'B');
    });

    test('a response never completes another request', () async {
      final a = api.request('peg', {'peg_in': true});
      final b = api.request('peg', {'peg_in': false});
      await pumpEventQueue();

      final idA = jsonDecode(ws.sent[0])['id'] as int;

      ws.inject({
        'id': idA,
        'method': 'peg',
        'result': {'order_id': 'only-A'},
      });

      expect((await a)['order_id'], 'only-A');

      // B must still be waiting — under the old first-emission logic it
      // would already have resolved with A's payload.
      expect(await _settled(b), isFalse);
    });

    test('an unknown id is ignored, not misrouted', () async {
      final a = api.request('peg', {'peg_in': true});
      await pumpEventQueue();

      ws.inject({
        'id': 999999,
        'method': 'peg',
        'result': {'order_id': 'X'},
      });
      await pumpEventQueue();

      expect(await _settled(a), isFalse);
    });
  });

  group('errors and timeouts', () {
    test(
      'a JSON-RPC error becomes SideswapRequestError with its message',
      () async {
        final f = api.request('peg', {'peg_in': true});
        await pumpEventQueue();
        final id = jsonDecode(ws.sent.single)['id'] as int;

        ws.inject({
          'id': id,
          'error': {'code': -1, 'message': 'peg disabled'},
        });

        await expectLater(f, throwsA(isA<SideswapRequestError>()));
        try {
          await f;
        } on SideswapRequestError catch (e) {
          expect(e.method, 'peg');
          expect(e.message, 'peg disabled');
        }
      },
    );

    test('a non-map result is rejected rather than silently cast', () async {
      final f = api.request('peg', {'peg_in': true});
      await pumpEventQueue();
      final id = jsonDecode(ws.sent.single)['id'] as int;

      ws.inject({'id': id, 'method': 'peg', 'result': 'not-an-object'});

      await expectLater(f, throwsA(isA<SideswapRequestError>()));
    });

    test('times out with the method name and duration', () async {
      final f = api.request('peg', {
        'peg_in': true,
      }, timeout: const Duration(milliseconds: 30));

      await expectLater(f, throwsA(isA<SideswapRequestTimeout>()));
      try {
        await f;
      } on SideswapRequestTimeout catch (e) {
        expect(e.method, 'peg');
        expect(e.timeout, const Duration(milliseconds: 30));
      }
    });

    test(
      'a late response after a timeout does not throw into the zone',
      () async {
        final f = api.request('peg', {
          'peg_in': true,
        }, timeout: const Duration(milliseconds: 20));
        await pumpEventQueue();
        final id = jsonDecode(ws.sent.single)['id'] as int;

        await expectLater(f, throwsA(isA<SideswapRequestTimeout>()));

        // The pending entry was removed in the `finally`, so this is a no-op
        // rather than a completion of an already-completed completer.
        ws.inject({
          'id': id,
          'method': 'peg',
          'result': {'order_id': 'late'},
        });
        await pumpEventQueue();
      },
    );

    test('dispose fails every in-flight request instead of hanging', () async {
      final a = api.request('peg', {'peg_in': true});
      final b = api.request('peg_status', {'order_id': 'z'});
      await pumpEventQueue();

      api.dispose();

      await expectLater(a, throwsA(isA<SideswapRequestError>()));
      await expectLater(b, throwsA(isA<SideswapRequestError>()));
    });

    test('requests after dispose fail fast', () async {
      api.dispose();
      await expectLater(
        api.request('peg', {'peg_in': true}),
        throwsA(isA<SideswapRequestError>()),
      );
    });
  });

  group('existing notification fan-out is preserved', () {
    test('quote notifications still reach the market stream', () async {
      // The asset-swap flow is notification-driven and must be unaffected by
      // correlation. Regression guard for Phase 14.
      final seen = <Map<String, dynamic>>[];
      final sub = api.marketStream.listen(seen.add);

      ws.inject({
        'method': 'market',
        'params': {
          'quote': {
            'status': {
              'Success': {'quote_id': 7},
            },
          },
        },
      });
      await pumpEventQueue();

      expect(seen, hasLength(1));
      expect(
        seen.single['params']['quote']['status']['Success']['quote_id'],
        7,
      );
      await sub.cancel();
    });

    test('a correlated response still fans out to its topic stream', () async {
      final seen = <Map<String, dynamic>>[];
      final sub = api.pegStream.listen(seen.add);

      final f = api.request('peg', {'peg_in': true});
      await pumpEventQueue();
      final id = jsonDecode(ws.sent.single)['id'] as int;

      ws.inject({
        'id': id,
        'method': 'peg',
        'result': {'order_id': 'A'},
      });

      expect((await f)['order_id'], 'A');
      await pumpEventQueue();
      expect(seen, hasLength(1), reason: 'fan-out must remain non-destructive');
      await sub.cancel();
    });
  });
}

/// Whether [future] has settled (either way) by the time the event queue
/// drains. Used to assert that a request is *still pending* — the property
/// that the old first-emission logic violated.
Future<bool> _settled(Future<Object?> future) async {
  var done = false;
  unawaited(
    future.then((_) => done = true, onError: (Object _) => done = true),
  );
  await pumpEventQueue();
  return done;
}

/// Drives the api's message pump without a socket. Subclasses the concrete
/// [WebSocketService] because it has no interface; the parent's own stream
/// controller is never listened to, so no real connection is ever dialled.
class _FakeTransport extends WebSocketService {
  _FakeTransport() : super(Uri.parse('wss://sideswap.test.invalid'));

  final StreamController<dynamic> _incoming =
      StreamController<dynamic>.broadcast();
  final List<String> sent = <String>[];

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  bool get isConnected => true;

  @override
  void send(dynamic data) => sent.add(data as String);

  @override
  Future<bool> ensureConnected() async => true;

  void inject(Map<String, dynamic> message) {
    if (!_incoming.isClosed) _incoming.add(jsonEncode(message));
  }

  @override
  void dispose() {
    if (!_incoming.isClosed) _incoming.close();
    super.dispose();
  }
}
