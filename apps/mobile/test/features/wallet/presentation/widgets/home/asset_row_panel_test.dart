import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/expanding_glass_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/asset_row.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';

import '../../../../../shared/test_app.dart';

/// A panel of two rows. A tap on a row opens a sheet with a close button
/// through the route of the market sheet.
Widget _panel() => wrapForTest(
  Scaffold(
    body: Padding(
      padding: const EdgeInsets.fromLTRB(20, 300, 20, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: AssetRowPanel(
          rows: [
            for (var i = 0; i < 2; i++)
              Builder(
                builder: (context) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showExpandingGlassSheet<void>(
                    context,
                    builder: (sheetContext) => SizedBox(
                      height: 300,
                      child: Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('close'),
                        ),
                      ),
                    ),
                  ),
                  child: SizedBox(height: 72, child: Text('row $i')),
                ),
              ),
          ],
        ),
      ),
    ),
  ),
);

/// The slice of the panel that belongs to row [index], measured from the
/// rendered panel and hairline: the first row runs from the panel top to
/// the hairline, the second from the hairline to the panel bottom.
Rect _slice(WidgetTester tester, int index) {
  final panel = tester.getRect(find.byType(GlassPanel));
  final divider = tester.getRect(find.byType(PanelDivider));
  return index == 0
      ? Rect.fromLTRB(panel.left, panel.top, panel.right, divider.top)
      : Rect.fromLTRB(panel.left, divider.top, panel.right, panel.bottom);
}

/// Bounds of the sheet glass. The panel glass comes first in the tree.
Rect _sheetGlass(WidgetTester tester) =>
    tester.getRect(find.byType(LiquidGlass).last);

void _expectRect(Rect actual, Rect expected) {
  expect(actual.left, moreOrLessEquals(expected.left, epsilon: 0.5));
  expect(actual.top, moreOrLessEquals(expected.top, epsilon: 0.5));
  expect(actual.right, moreOrLessEquals(expected.right, epsilon: 0.5));
  expect(actual.bottom, moreOrLessEquals(expected.bottom, epsilon: 0.5));
}

void main() {
  testWidgets('the row origins tile the panel, hairline included', (
    tester,
  ) async {
    await tester.pumpWidget(_panel());

    final origins = find.byType(GlassSheetOrigin);
    _expectRect(tester.getRect(origins.at(0)), _slice(tester, 0));
    _expectRect(tester.getRect(origins.at(1)), _slice(tester, 1));
    // The outer corners follow the panel corners.
    expect(
      tester.widget<GlassSheetOrigin>(origins.at(0)).borderRadius,
      BorderRadius.only(
        topLeft: AppSurfaces.panelRadius.topLeft,
        topRight: AppSurfaces.panelRadius.topRight,
      ),
    );
    expect(
      tester.widget<GlassSheetOrigin>(origins.at(1)).borderRadius,
      BorderRadius.only(
        bottomLeft: AppSurfaces.panelRadius.bottomLeft,
        bottomRight: AppSurfaces.panelRadius.bottomRight,
      ),
    );
  });

  for (final index in [0, 1]) {
    testWidgets('the sheet opens from and closes into the slice of row '
        '${index + 1}', (tester) async {
      await tester.pumpWidget(_panel());
      final slice = _slice(tester, index);

      await tester.tap(find.text('row $index'));
      await tester.pump();
      _expectRect(_sheetGlass(tester), slice);
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('close'));
      await tester.pump();
      var last = _sheetGlass(tester);
      while (find.text('close').evaluate().isNotEmpty) {
        last = _sheetGlass(tester);
        await tester.pump(const Duration(milliseconds: 16));
      }
      _expectRect(last, slice);
    });
  }
}
