import 'package:flutter_test/flutter_test.dart';

/// Turns on the system "reduce motion" setting for the current test.
///
/// `MediaQuery.disableAnimationsOf` reads this setting through the
/// MaterialApp media query.
void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}
