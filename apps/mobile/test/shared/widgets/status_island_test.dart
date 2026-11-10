import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/header.dart';
import 'package:mooze_mobile/shared/widgets/status_island.dart';
import 'package:mooze_mobile/themes/app_text_styles.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  // The corner test measures the labels. The wide test font would not fit,
  // so the tests load the app font.
  setUpAll(() async {
    final loader = FontLoader(AppTextStyles.fontFamily);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(
        rootBundle.load('assets/fonts/geist-font/Geist/ttf/Geist-$weight.ttf'),
      );
    }
    await loader.load();
  });

  late ValueNotifier<(bool, bool, bool)> status;
  late ValueNotifier<double> pull;
  late int offlineTaps;
  late int syncErrorTaps;

  setUp(() {
    offlineTaps = 0;
    syncErrorTaps = 0;
  });

  /// The island with ([offline], [loading], [syncError]). [status] changes
  /// them later, and [pull] sets the pull of a pull-to-refresh.
  Future<void> pump(
    WidgetTester tester, {
    required bool offline,
    required bool loading,
    bool syncError = false,
    bool reducedMotion = false,
  }) async {
    status = ValueNotifier((offline, loading, syncError));
    pull = ValueNotifier(0);
    addTearDown(status.dispose);
    addTearDown(pull.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reducedMotion),
          child: Theme(data: AppTheme.darkTheme(context), child: child!),
        ),
        home: Scaffold(
          body: Column(
            children: [
              ListenableBuilder(
                listenable: Listenable.merge([status, pull]),
                builder: (context, _) => StatusIsland(
                  offline: status.value.$1,
                  loading: status.value.$2,
                  pull: pull.value,
                  loadingLabel: 'Sync',
                  loadingSemanticsLabel: 'Carregando transações...',
                  syncError: status.value.$3,
                  syncErrorLabel: 'Erro',
                  syncErrorSemanticsLabel: 'Erro de Sincronização',
                  onOfflineTap: () => offlineTaps++,
                  onSyncErrorTap: () => syncErrorTaps++,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // The sync icon turns forever, so the test pumps a fixed time.
    await tester.pump(const Duration(seconds: 1));
  }

  Rect offlinePart(WidgetTester tester) =>
      tester.getRect(find.byKey(StatusIsland.offlineKey));

  Rect loadingPart(WidgetTester tester) =>
      tester.getRect(find.byKey(StatusIsland.loadingKey));

  Rect syncErrorPart(WidgetTester tester) =>
      tester.getRect(find.byKey(StatusIsland.syncErrorKey));

  /// The angle of the sync icon, in turns, from -0.5 to 0.5.
  double syncTurns(WidgetTester tester) {
    final rotation = tester
        .widget<Transform>(
          find
              .ancestor(
                of: find.byIcon(Icons.sync_rounded),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform;
    return math.atan2(rotation.entry(1, 0), rotation.entry(0, 0)) /
        (2 * math.pi);
  }

  Size island(WidgetTester tester) => tester.getSize(
    find
        .descendant(
          of: find.byType(StatusIsland),
          matching: find.byType(CustomPaint),
        )
        .first,
  );

  testWidgets('offline alone is the full pill with its label', (tester) async {
    await pump(tester, offline: true, loading: false);

    final offline = offlinePart(tester);
    expect(offline.width, greaterThan(offline.height * 2));
    expect(find.byKey(StatusIsland.loadingKey), findsNothing);
    expect(island(tester).width, offline.width);
  });

  testWidgets('offline with a loading: the loading leads, the offline is a '
      'dot beside it, and a bridge joins them', (tester) async {
    await pump(tester, offline: true, loading: true);

    final offline = offlinePart(tester);
    final loading = loadingPart(tester);
    expect(offline.width, moreOrLessEquals(offline.height));
    expect(loading.width, greaterThan(offline.width * 2));
    expect(offline.right, lessThan(loading.left));
    expect(loading.left - offline.right, moreOrLessEquals(8));
    expect(loading.height, offline.height);
  });

  testWidgets('when the loading ends offline, the loading leaves and the '
      'offline opens back, without a jump', (tester) async {
    await pump(tester, offline: true, loading: true);
    final dot = offlinePart(tester).width;

    status.value = (true, false, false);
    final widths = <double>[];
    final times = <Duration>[];
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      widths.add(offlinePart(tester).width);
      times.add(tester.binding.currentSystemFrameTimeStamp);
    }
    final full = widths.last;

    expect(find.byKey(StatusIsland.loadingKey), findsNothing);
    expect(full, greaterThan(dot * 2));
    // The first frame is still close to the dot: no instant change.
    expect(widths.first, lessThan(dot + (full - dot) * 0.2));
    // No frame moves faster than the whole way in a tenth of a second. The
    // check uses the time between frames: on a device, `flutter run` pumps
    // in real time, and a debug build skips frames.
    for (var i = 1; i < widths.length; i++) {
      final seconds = (times[i] - times[i - 1]).inMicroseconds / 1e6;
      if (seconds == 0) continue;
      expect(
        (widths[i] - widths[i - 1]).abs() / seconds,
        lessThan((full - dot) * 10),
        reason: 'frame $i',
      );
    }
  });

  testWidgets('online with a loading: the loading alone, with no room for '
      'the offline', (tester) async {
    await pump(tester, offline: false, loading: true);

    expect(find.byKey(StatusIsland.offlineKey), findsNothing);
    expect(island(tester).width, loadingPart(tester).width);
  });

  testWidgets('back online during a loading, the offline dot leaves and the '
      'loading keeps its size', (tester) async {
    await pump(tester, offline: true, loading: true);
    final loadingWidth = loadingPart(tester).width;

    status.value = (false, true, false);
    // The first frame starts the morph; the next one moves it.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(StatusIsland.offlineKey), findsNothing);
    expect(loadingPart(tester).width, moreOrLessEquals(loadingWidth));
    expect(island(tester).width, moreOrLessEquals(loadingWidth));
  });

  testWidgets('online and idle, the island shrinks away and takes no space', (
    tester,
  ) async {
    await pump(tester, offline: true, loading: false);
    expect(island(tester).height, greaterThan(0));

    status.value = (false, false, false);
    await tester.pump(const Duration(milliseconds: 16));
    expect(island(tester).height, greaterThan(0));

    await tester.pumpAndSettle();
    expect(island(tester).height, 0);
    expect(find.byKey(StatusIsland.offlineKey), findsNothing);
  });

  testWidgets('a tap on the offline dot opens the offline details, also '
      'just outside the dot', (tester) async {
    await pump(tester, offline: true, loading: true);
    final dot = offlinePart(tester);

    await tester.tapAt(dot.center);
    // The tap target spans the 48 point row, above the 28 point dot.
    await tester.tapAt(dot.center.translate(0, -20));

    expect(offlineTaps, 2);
  });

  testWidgets('with reduced motion, the island takes the new shape at once', (
    tester,
  ) async {
    await pump(tester, offline: true, loading: false, reducedMotion: true);

    status.value = (true, true, false);
    await tester.pump();

    final offline = offlinePart(tester);
    expect(offline.width, moreOrLessEquals(offline.height));
    expect(loadingPart(tester).height, offline.height);
  });

  testWidgets('screen readers hear Offline as a button and the full loading '
      'label, while the pill shows the short one', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, offline: true, loading: true);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Offline')),
      matchesSemantics(label: 'Offline', isButton: true, hasTapAction: true),
    );
    expect(find.bySemanticsLabel('Carregando transações...'), findsOneWidget);
    expect(find.text('Sync'), findsOneWidget);
    semantics.dispose();
  });

  // A 375 point phone, with the 20 point side margins of the home. The
  // English error label is the widest one.
  for (final (name, loading, syncError, lead, label) in [
    ('offline alone', false, false, StatusIsland.offlineKey, 'Offline'),
    ('offline and loading', true, false, StatusIsland.loadingKey, 'Sync'),
    (
      'offline and a failed sync',
      false,
      true,
      StatusIsland.syncErrorKey,
      'Error',
    ),
    ('all three', true, true, StatusIsland.syncErrorKey, null),
  ]) {
    testWidgets('in the corner of the home header, $name fit between the '
        'logo and the edge of a small phone', (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 300 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  LogoHeader(
                    status: StatusIsland(
                      alignment: Alignment.centerRight,
                      offline: true,
                      loading: loading,
                      loadingLabel: 'Sync',
                      syncError: syncError,
                      syncErrorLabel: 'Error',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final header = tester.getRect(find.byType(LogoHeader));
      final logo = tester.getRect(
        find.byWidgetPredicate((w) => w is SvgPicture && w.width == logoWidth),
      );
      final offline = offlinePart(tester);
      final leader = tester.getRect(find.byKey(lead));

      expect(leader.right, moreOrLessEquals(header.right));
      expect(offline.left, greaterThanOrEqualTo(logo.right));
      expect(offline.right, lessThanOrEqualTo(header.right));
      expect(offline.center.dy, moreOrLessEquals(header.center.dy));
      if (label != null) {
        // The lead label shows whole, with no ellipsis.
        expect(leader.width, greaterThan(leader.height * 2));
        expect(
          tester
              .renderObject<RenderParagraph>(find.text(label))
              .didExceedMaxLines,
          isFalse,
        );
      }
    });
  }

  testWidgets('in the corner, every frame of a morph stays between the logo '
      'and the edge', (tester) async {
    tester.view.physicalSize = const Size(375 * 3, 300 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final corner = ValueNotifier((true, true, false));
    addTearDown(corner.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            Theme(data: AppTheme.darkTheme(context), child: child!),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: corner,
                  builder: (context, value, _) => LogoHeader(
                    status: StatusIsland(
                      alignment: Alignment.centerRight,
                      offline: value.$1,
                      loading: value.$2,
                      loadingLabel: 'Sync',
                      syncError: value.$3,
                      syncErrorLabel: 'Error',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final header = tester.getRect(find.byType(LogoHeader));
    final logo = tester.getRect(
      find.byWidgetPredicate((w) => w is SvgPicture && w.width == logoWidth),
    );

    // The error arrives, then leaves: a pill closes while a dot grows.
    for (final next in [(true, true, true), (true, false, true)]) {
      corner.value = next;
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        for (final key in [
          StatusIsland.offlineKey,
          StatusIsland.loadingKey,
          StatusIsland.syncErrorKey,
        ]) {
          final part = find.byKey(key);
          if (part.evaluate().isEmpty) continue;
          final rect = tester.getRect(part);
          expect(rect.left, greaterThanOrEqualTo(logo.right), reason: '$key');
          expect(
            rect.right,
            lessThanOrEqualTo(header.right + 0.5),
            reason: '$key, frame $frame',
          );
        }
      }
    }
  });

  testWidgets('offline with a failed sync: the error leads, and the offline '
      'is a dot beside it', (tester) async {
    await pump(tester, offline: true, loading: false, syncError: true);

    final offline = offlinePart(tester);
    final error = syncErrorPart(tester);
    expect(offline.width, moreOrLessEquals(offline.height));
    expect(error.width, greaterThan(offline.width * 2));
    expect(error.left - offline.right, moreOrLessEquals(8));
  });

  testWidgets('a failed sync during a loading: the error leads, and the '
      'loading is a dot', (tester) async {
    await pump(tester, offline: false, loading: true, syncError: true);

    final loading = loadingPart(tester);
    expect(loading.width, moreOrLessEquals(loading.height));
    expect(syncErrorPart(tester).width, greaterThan(loading.width * 2));
  });

  testWidgets('all three: three dots in order, and each dot opens its own '
      'details', (tester) async {
    await pump(tester, offline: true, loading: true, syncError: true);

    final offline = offlinePart(tester);
    final loading = loadingPart(tester);
    final error = syncErrorPart(tester);
    for (final part in [offline, loading, error]) {
      expect(part.width, moreOrLessEquals(part.height));
    }
    expect(offline.right, lessThan(loading.left));
    expect(loading.right, lessThan(error.left));

    await tester.tapAt(offline.center);
    await tester.tapAt(error.center);
    await tester.tapAt(loading.center);
    expect(offlineTaps, 1);
    expect(syncErrorTaps, 1);
  });

  testWidgets('when the sync recovers, the error leaves and the loading '
      'leads again', (tester) async {
    await pump(tester, offline: true, loading: true, syncError: true);

    status.value = (true, true, false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(StatusIsland.syncErrorKey), findsNothing);
    final offline = offlinePart(tester);
    expect(offline.width, moreOrLessEquals(offline.height));
    expect(loadingPart(tester).width, greaterThan(offline.width * 2));
  });

  testWidgets('screen readers hear the failed sync as a button with its full '
      'name', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, offline: false, loading: false, syncError: true);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Erro de Sincronização')),
      matchesSemantics(
        label: 'Erro de Sincronização',
        isButton: true,
        hasTapAction: true,
        isLiveRegion: true,
      ),
    );
    semantics.dispose();
  });

  group('pull-to-refresh', () {
    testWidgets('a pull brings the loading part in with the finger, with '
        'no spring', (tester) async {
      await pump(tester, offline: false, loading: false);

      final widths = <double>[];
      for (final value in [0.2, 0.6, 1.0]) {
        pull.value = value;
        await tester.pump();
        final rect = loadingPart(tester);
        // The part stays where the finger put it.
        await tester.pump(const Duration(seconds: 1));
        expect(loadingPart(tester), rect, reason: 'pull $value');
        widths.add(rect.width);
      }

      expect(widths[0], lessThan(widths[1]));
      expect(widths[1], lessThan(widths[2]));
      // At the end of the pull the part shows its label. Early in the
      // pull it is a small dot.
      final opened = loadingPart(tester);
      expect(opened.width, greaterThan(opened.height * 2));
      pull.value = 0.2;
      await tester.pump();
      final early = loadingPart(tester);
      expect(early.width, moreOrLessEquals(early.height));
      expect(early.height, lessThan(opened.height));
    });

    testWidgets('offline, the pull closes the offline pill to a dot as the '
        'loading part opens', (tester) async {
      await pump(tester, offline: true, loading: false);
      final full = offlinePart(tester).width;

      pull.value = 0.5;
      await tester.pump();
      final halfway = offlinePart(tester);
      expect(halfway.width, inExclusiveRange(halfway.height, full));

      pull.value = 1;
      await tester.pump();
      expect(offlinePart(tester).width, moreOrLessEquals(halfway.height));
      expect(
        loadingPart(tester).width,
        greaterThan(offlinePart(tester).width * 2),
      );
    });

    testWidgets('a release into a refresh springs on to the loading from '
        'where the pull left it', (tester) async {
      await pump(tester, offline: true, loading: false);
      pull.value = 0.6;
      await tester.pump();
      final pulled = loadingPart(tester).width;

      // The release ends the pull, and the refresh starts the loading.
      status.value = (true, true, false);
      pull.value = 0;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(loadingPart(tester).width, moreOrLessEquals(pulled, epsilon: 6));

      await tester.pump(const Duration(seconds: 1));
      final offline = offlinePart(tester);
      expect(offline.width, moreOrLessEquals(offline.height));
      expect(loadingPart(tester).width, greaterThan(offline.width * 2));
    });

    testWidgets('a short pull springs back to the island before it', (
      tester,
    ) async {
      await pump(tester, offline: true, loading: false);
      final before = offlinePart(tester);

      pull.value = 0.6;
      await tester.pump();
      pull.value = 0;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(StatusIsland.loadingKey), findsNothing);
      expect(offlinePart(tester), before);
    });

    testWidgets('the sync icon winds with the pull, and spins on from there', (
      tester,
    ) async {
      await pump(tester, offline: false, loading: false);

      pull.value = 0.5;
      await tester.pump();
      expect(syncTurns(tester), moreOrLessEquals(0.25));
      pull.value = 1;
      await tester.pump();
      expect(syncTurns(tester).abs(), moreOrLessEquals(0.5));

      status.value = (false, true, false);
      pull.value = 0;
      await tester.pump();
      expect(syncTurns(tester).abs(), moreOrLessEquals(0.5));
      await tester.pump(const Duration(milliseconds: 300));
      expect(syncTurns(tester).abs(), lessThan(0.4));
    });

    testWidgets('an island built during a pull shows the pull at once', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          home: const Scaffold(
            body: Column(
              children: [
                StatusIsland(
                  offline: false,
                  loading: false,
                  pull: 1,
                  loadingLabel: 'Sync',
                ),
              ],
            ),
          ),
        ),
      );

      final loading = loadingPart(tester);
      expect(loading.width, greaterThan(loading.height * 2));
    });

    testWidgets('during a loading, a pull changes nothing', (tester) async {
      await pump(tester, offline: true, loading: true);
      final loading = loadingPart(tester);
      final offline = offlinePart(tester);

      pull.value = 0.5;
      await tester.pump();

      expect(loadingPart(tester), loading);
      expect(offlinePart(tester), offline);
    });
  });
}
