import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// What the user picked on the market chart: one point while scrubbing, or
/// a range between two points.
///
/// Indices point at real points of the history. A selection never holds a
/// value between two points.
sealed class MarketSelection {
  const MarketSelection();

  /// Returns true when every index fits a history of [length] points.
  bool fits(int length);
}

/// The point under the finger while the user scrubs.
@immutable
final class MarketPoint extends MarketSelection {
  const MarketPoint(this.index);

  final int index;

  @override
  bool fits(int length) => index < length;

  @override
  bool operator ==(Object other) =>
      other is MarketPoint && other.index == index;

  @override
  int get hashCode => index.hashCode;
}

/// A range between two markers. The markers can cross: [from] is always
/// the earlier point and [to] the later one.
@immutable
final class MarketRange extends MarketSelection {
  const MarketRange(this.a, this.b);

  /// The markers, in the order the user placed them.
  final int a;
  final int b;

  /// The earlier point.
  int get from => math.min(a, b);

  /// The later point.
  int get to => math.max(a, b);

  /// Returns the range with the marker nearest to [index] moved to
  /// [index]. On a tie, the marker placed last moves.
  MarketRange moveNearest(int index) => (index - a).abs() < (index - b).abs()
      ? MarketRange(index, b)
      : MarketRange(a, index);

  @override
  bool fits(int length) => math.max(a, b) < length;

  @override
  bool operator ==(Object other) =>
      other is MarketRange && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash(a, b);
}
