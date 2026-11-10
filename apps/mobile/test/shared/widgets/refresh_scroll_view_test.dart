import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/widgets/refresh_scroll_view.dart';
import 'package:mooze_mobile/shared/widgets/status_island.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// Rows of 100 high. The test view is 600 high, so 3 rows fit and 20 rows
/// scroll.
const double _rowHeight = 100;

/// A screen like the home: a header with the status island, then rows. The
/// content changes when the refresh starts, as new data arrives in the app.
class _Screen extends StatefulWidget {
  const _Screen({
    required this.rows,
    required this.refreshRows,
    required this.refresh,
  });

  final int rows;

  /// Rows while the refresh runs.
  final int refreshRows;

  /// Completes the refresh.
  final Completer<void> refresh;

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  final pull = PullRefreshController();
  bool _refreshing = false;
  int refreshes = 0;

  Future<void> _onRefresh() async {
    refreshes++;
    setState(() => _refreshing = true);
    await widget.refresh.future;
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  void dispose() {
    pull.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _refreshing ? widget.refreshRows : widget.rows;
    return MaterialApp(
      // The island reads the colors of the app theme.
      builder: (context, child) =>
          Theme(data: AppTheme.darkTheme(context), child: child!),
      home: Scaffold(
        body: RefreshScrollView(
          controller: pull,
          onRefresh: _onRefresh,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                key: const ValueKey('top'),
                height: 56,
                // As in the home, the island shows the pull and the
                // refresh.
                child: ListenableBuilder(
                  listenable: pull,
                  builder: (context, _) => StatusIsland(
                    alignment: Alignment.centerRight,
                    offline: false,
                    loading: pull.refreshing,
                    pull: pull.progress,
                    loadingLabel: 'Sync',
                  ),
                ),
              ),
              // New text with the same size still lays the content out.
              Text(_refreshing ? 'Syncing' : 'Idle'),
              for (var i = 0; i < rows; i++)
                SizedBox(height: _rowHeight, child: Text('row $i')),
            ],
          ),
        ),
      ),
    );
  }
}

_ScreenState _state(WidgetTester tester) =>
    tester.state<_ScreenState>(find.byType(_Screen));

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable)).position;

/// Drags the content down from the top by [moves] steps of 15, and keeps
/// the finger down.
Future<TestGesture> _drag(WidgetTester tester, {int moves = 20}) async {
  final gesture = await tester.startGesture(const Offset(200, 200));
  for (var i = 0; i < moves; i++) {
    await gesture.moveBy(const Offset(0, 15));
    await tester.pump(const Duration(milliseconds: 16));
  }
  return gesture;
}

/// Pulls the content down from the top and lets go.
Future<void> _pull(WidgetTester tester, {int moves = 20}) async {
  final gesture = await _drag(tester, moves: moves);
  await gesture.up();
}

/// Pumps the frames after the pull and returns the scroll offset and the
/// time of each.
Future<List<(double, Duration)>> _framesAfterPull(WidgetTester tester) async {
  final frames = <(double, Duration)>[];
  for (var i = 0; i < 90; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    frames.add((
      _position(tester).pixels,
      tester.binding.currentSystemFrameTimeStamp,
    ));
  }
  return frames;
}

final _bothPlatforms = TargetPlatformVariant({
  TargetPlatform.iOS,
  TargetPlatform.android,
});

void main() {
  group('RefreshScrollView on iOS', () {
    // The pull overscrolls on iOS. The refresh starts while the content
    // springs back, and the new content lays out during the spring.
    for (final (rows, refreshRows) in [(20, 20), (20, 23), (20, 3), (3, 6)]) {
      testWidgets(
        'springs back to the top when the content changes '
        '($rows to $refreshRows rows)',
        (tester) async {
          final refresh = Completer<void>();
          await tester.pumpWidget(
            _Screen(rows: rows, refreshRows: refreshRows, refresh: refresh),
          );

          await _pull(tester);
          expect(_position(tester).pixels, lessThan(-60));
          final frames = await _framesAfterPull(tester);
          final offsets = [for (final (offset, _) in frames) offset];

          expect(_state(tester).refreshes, 1);

          // The page never scrolls into the content.
          expect(offsets.reduce((a, b) => a > b ? a : b), lessThan(0.5));
          // The spring stays slow: it never jumps to the top. The check uses
          // the time between frames: on a device, `flutter run` pumps in real
          // time, and a debug build skips frames.
          for (var i = 1; i < frames.length; i++) {
            final (offset, time) = frames[i];
            final (lastOffset, lastTime) = frames[i - 1];
            final seconds = (time - lastTime).inMicroseconds / 1e6;
            if (seconds == 0) continue;
            expect(
              (offset - lastOffset).abs() / seconds,
              lessThan(1000),
              reason: 'frame $i',
            );
          }
          expect(offsets.last, 0);
          expect(tester.getTopLeft(find.byKey(const ValueKey('top'))).dy, 8);

          refresh.complete();
          await tester.pumpAndSettle();
          expect(_position(tester).pixels, 0);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );
    }
  });

  testWidgets(
    'stays at the top on Android when the content changes',
    (tester) async {
      final refresh = Completer<void>();
      await tester.pumpWidget(
        _Screen(rows: 20, refreshRows: 23, refresh: refresh),
      );

      await _pull(tester);
      final frames = await _framesAfterPull(tester);

      expect(_state(tester).refreshes, 1);
      expect(frames.every((frame) => frame.$1 == 0), isTrue);

      refresh.complete();
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'on Android, the content does not stretch during a pull',
    (tester) async {
      final refresh = Completer<void>()..complete();
      await tester.pumpWidget(
        _Screen(rows: 20, refreshRows: 20, refresh: refresh),
      );
      final top = find.byKey(const ValueKey('top'));
      final rest = tester.getTopLeft(top);

      final gesture = await tester.startGesture(const Offset(200, 200));
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(const Offset(0, 15));
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.getTopLeft(top), rest, reason: 'move $i');
      }
      await gesture.up();
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('a pull reports how far it went, and a release past the arm '
      'distance refreshes until the refresh completes', (tester) async {
    final refresh = Completer<void>();
    await tester.pumpWidget(
      _Screen(rows: 20, refreshRows: 20, refresh: refresh),
    );
    final pull = _state(tester).pull;

    final gesture = await _drag(tester, moves: 6);
    expect(pull.progress, inExclusiveRange(0, 1));
    final halfway = pull.progress;
    for (var i = 0; i < 14; i++) {
      await gesture.moveBy(const Offset(0, 15));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(pull.progress, greaterThan(halfway));
    expect(pull.progress, 1);
    expect(pull.refreshing, isFalse);

    await gesture.up();
    // On iOS the release shows when the content starts to spring back, in
    // the second frame.
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(pull.progress, 0);
    expect(pull.refreshing, isTrue);
    expect(_state(tester).refreshes, 1);

    await tester.pump(const Duration(seconds: 2));
    expect(pull.refreshing, isTrue);

    refresh.complete();
    await tester.pumpAndSettle();
    expect(pull.refreshing, isFalse);
  }, variant: _bothPlatforms);

  testWidgets('a short pull springs back and does not refresh', (
    tester,
  ) async {
    final refresh = Completer<void>()..complete();
    await tester.pumpWidget(
      _Screen(rows: 20, refreshRows: 20, refresh: refresh),
    );
    final pull = _state(tester).pull;

    final gesture = await _drag(tester, moves: 6);
    expect(pull.progress, inExclusiveRange(0, 1));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(pull.progress, 0);
    expect(pull.refreshing, isFalse);
    expect(_state(tester).refreshes, 0);
    expect(find.byKey(StatusIsland.loadingKey), findsNothing);
  }, variant: _bothPlatforms);

  testWidgets('a haptic marks the point where a release refreshes, once', (
    tester,
  ) async {
    final haptics = <Object?>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final refresh = Completer<void>()..complete();
    await tester.pumpWidget(
      _Screen(rows: 20, refreshRows: 20, refresh: refresh),
    );

    final gesture = await _drag(tester, moves: 6);
    expect(haptics, isEmpty);
    for (var i = 0; i < 14; i++) {
      await gesture.moveBy(const Offset(0, 15));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(haptics, ['HapticFeedbackType.mediumImpact']);
  });

  testWidgets('the island is the only indicator: the pull brings its '
      'loading part in, and the refresh keeps it', (tester) async {
    final refresh = Completer<void>();
    await tester.pumpWidget(
      _Screen(rows: 20, refreshRows: 20, refresh: refresh),
    );
    expect(find.byKey(StatusIsland.loadingKey), findsNothing);

    final gesture = await _drag(tester, moves: 6);
    expect(find.byKey(StatusIsland.loadingKey), findsOneWidget);

    for (var i = 0; i < 14; i++) {
      await gesture.moveBy(const Offset(0, 15));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(StatusIsland.loadingKey), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ProgressIndicator || widget is CupertinoActivityIndicator,
      ),
      findsNothing,
    );

    refresh.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(StatusIsland.loadingKey), findsNothing);
  }, variant: _bothPlatforms);

  testWidgets('a pull during a refresh does nothing', (tester) async {
    final refresh = Completer<void>();
    await tester.pumpWidget(
      _Screen(rows: 20, refreshRows: 20, refresh: refresh),
    );
    final pull = _state(tester).pull;

    await _pull(tester);
    await tester.pump(const Duration(seconds: 1));
    await _pull(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(_state(tester).refreshes, 1);
    expect(pull.progress, 0);
    expect(pull.refreshing, isTrue);

    refresh.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('refreshes short content that does not scroll', (tester) async {
    final refresh = Completer<void>()..complete();
    await tester.pumpWidget(_Screen(rows: 1, refreshRows: 1, refresh: refresh));

    await _pull(tester);
    await tester.pumpAndSettle();

    expect(_state(tester).refreshes, 1);
  });

  testWidgets('puts the padding around the content', (tester) async {
    final refresh = Completer<void>()..complete();
    await tester.pumpWidget(_Screen(rows: 3, refreshRows: 3, refresh: refresh));

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('top'))),
      const Offset(20, 8),
    );
  });
}
