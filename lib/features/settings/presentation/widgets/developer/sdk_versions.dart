import 'dart:convert' show utf8;
import 'dart:typed_data' show Uint8List;

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
    final lock = await _readLockfile();
    if (lock == null) return unavailable;

    return SdkVersions(
      lwk: _versionFor(lock, 'lwk') ?? 'unavailable',
      bdk: _versionFor(lock, 'bdk_flutter') ?? 'unavailable',
      breez: _versionFor(lock, 'flutter_breez_liquid') ?? 'unavailable',
    );
  }

  static Future<String?> _readLockfile() async {
    try {
      final data = await rootBundle.load('pubspec.lock');
      return utf8.decode(Uint8List.sublistView(data));
    } catch (_) {
      return null;
    }
  }

  static String? _versionFor(String lockfile, String packageName) {
    final pattern = RegExp(
      '^  ${RegExp.escape(packageName)}:\$.*?^    version:\\s*"?([^"\\n]+?)"?\\s*\$',
      multiLine: true,
      dotAll: true,
    );
    return pattern.firstMatch(lockfile)?.group(1)?.trim();
  }
}

final sdkVersionsProvider = FutureProvider<SdkVersions>((ref) {
  return SdkVersions.load();
});
