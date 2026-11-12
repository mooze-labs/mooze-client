import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/glyph_colors.dart';

void main() {
  test('the color of each asset comes from its icon', () {
    for (final asset in Asset.values) {
      final icon = File(asset.iconPath).readAsStringSync().toUpperCase();
      final rgb = CoinGlyphColors.colorOf(asset)
          .toARGB32()
          .toRadixString(16)
          .toUpperCase()
          .substring(2);
      expect(icon, contains('#$rgb'), reason: '$asset');
    }
  });

  test('each asset has a color of its own', () {
    final colors = Asset.values.map(CoinGlyphColors.colorOf).toSet();
    expect(colors, hasLength(Asset.values.length));
  });
}
