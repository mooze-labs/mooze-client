import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SdkVersions {
  const SdkVersions({
    required this.lwk,
    required this.bdk,
    required this.breez,
  });

  final String lwk;
  final String bdk;
  final String breez;

  static const SdkVersions loading = SdkVersions(lwk: '…', bdk: '…', breez: '…');


  static const SdkVersions unavailable = SdkVersions(
    lwk: 'unavailable',
    bdk: 'unavailable',
    breez: 'unavailable',
  );

  static Future<SdkVersions> load() async {
    final results = await Future.wait([
      _readVersion('packages/lwk-dart/pubspec.yaml'),
      _readVersion('packages/bdk-flutter/pubspec.yaml'),
      _readVersion('packages/breez-sdk-liquid-flutter/pubspec.yaml'),
    ]);

    return SdkVersions(
      lwk: results[0] ?? 'unavailable',
      bdk: results[1] ?? 'unavailable',
      breez: results[2] ?? 'unavailable',
    );
  }

  static Future<String?> _readVersion(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath, cache: true);
      final match = RegExp(r'^version:\s*([^\s#]+)', multiLine: true)
          .firstMatch(raw);
      return match?.group(1)?.trim();
    } catch (_) {
      return null;
    }
  }
}

final sdkVersionsProvider = FutureProvider<SdkVersions>((ref) {
  return SdkVersions.load();
});
