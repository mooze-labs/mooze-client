import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

void main() {
  test('L-BTC is Liquid Bitcoin, with its own ticker and icon', () {
    expect(Asset.lbtc.name, 'Liquid Bitcoin');
    expect(Asset.lbtc.displayName, 'Liquid Bitcoin');
    expect(Asset.lbtc.ticker, 'L-BTC');
    expect(Asset.lbtc.iconPath, 'assets/icons/asset/lbtc.svg');
  });

  test('the icon of every asset is in the app assets, on a square canvas, '
      'so the icons line up in a row', () {
    for (final asset in Asset.values) {
      final file = File(asset.iconPath);
      expect(file.existsSync(), isTrue, reason: asset.name);
      final svg = RegExp(r'<svg[^>]*>').firstMatch(file.readAsStringSync())!;
      String attribute(String name) =>
          RegExp('$name="([^"]*)"').firstMatch(svg[0]!)!.group(1)!;
      expect(attribute('width'), attribute('height'), reason: asset.name);
    }
  });
}
