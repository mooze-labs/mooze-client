import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_screen_scaffold.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  const statusBar = 47.0;
  const homeIndicator = 34.0;
  const height = 844.0;

  Future<void> open(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, height) * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(
      top: statusBar * 3,
      bottom: homeIndicator * 3,
    );
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            Theme(data: AppTheme.darkTheme(context), child: child!),
        home: PinScreenScaffold(appBarTitle: 'Validar PIN', child: child),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  /// The opacity the slice of the backdrop of the bar goes to.
  double backdrop(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(BackdropAppBar),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .opacity;

  testWidgets('the content starts at the top of the screen, under a clear '
      'bar, and fills the page below the bar as before', (tester) async {
    await open(
      tester,
      const Column(children: [Text('top'), Spacer(), Text('bottom')]),
    );

    expect(tester.getRect(find.byType(SingleChildScrollView)).top, 0);
    expect(backdrop(tester), 0);
    // Below the status bar and the bar, with the margin of the page.
    expect(
      tester.getRect(find.text('top')).top,
      statusBar + kToolbarHeight + 8,
    );
    // The content fills the page down to its bottom margin.
    expect(
      tester.getRect(find.text('bottom')).bottom,
      height - homeIndicator - 12,
    );
  });

  testWidgets('the bar takes its backdrop once the content scrolls under '
      'it', (tester) async {
    await open(tester, const SizedBox(height: 3000));
    expect(backdrop(tester), 0);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(backdrop(tester), 1);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 600));
    await tester.pump(const Duration(milliseconds: 400));
    expect(backdrop(tester), 0);
  });
}
