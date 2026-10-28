import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/themes/app_text_styles.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// Weight class and italic flag from the OS/2 table of a TrueType font.
({int weight, bool italic}) _os2(ByteData data) {
  final tableCount = data.getUint16(4);
  for (var i = 0; i < tableCount; i++) {
    final record = 12 + 16 * i;
    final tag = String.fromCharCodes([
      for (var j = 0; j < 4; j++) data.getUint8(record + j),
    ]);
    if (tag == 'OS/2') {
      final offset = data.getUint32(record + 8);
      return (
        weight: data.getUint16(offset + 4),
        italic: data.getUint16(offset + 62) & 1 == 1,
      );
    }
  }
  throw StateError('No OS/2 table');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the font manifest registers every Geist weight, upright and italic',
    () async {
      final manifest =
          jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
      final geist = manifest.cast<Map<String, dynamic>>().singleWhere(
        (family) => family['family'] == AppTextStyles.fontFamily,
      );
      final fonts = (geist['fonts'] as List).cast<Map<String, dynamic>>();

      expect(fonts, hasLength(18));
      for (final weight in [100, 200, 300, 400, 500, 600, 700, 800, 900]) {
        expect(
          fonts.where((f) => f['weight'] == weight && f['style'] == null),
          hasLength(1),
          reason: 'upright $weight',
        );
        expect(
          fonts.where((f) => f['weight'] == weight && f['style'] == 'italic'),
          hasLength(1),
          reason: 'italic $weight',
        );
      }
    },
  );

  test('each registered file has the declared weight and style', () async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    final geist = manifest.cast<Map<String, dynamic>>().singleWhere(
      (family) => family['family'] == AppTextStyles.fontFamily,
    );

    for (final font in (geist['fonts'] as List).cast<Map<String, dynamic>>()) {
      final asset = font['asset'] as String;
      final os2 = _os2(await rootBundle.load(asset));
      expect(os2.weight, font['weight'], reason: asset);
      expect(os2.italic, font['style'] == 'italic', reason: asset);
    }
  });

  test('the Geist files load as fonts', () async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    final geist = manifest.cast<Map<String, dynamic>>().singleWhere(
      (family) => family['family'] == AppTextStyles.fontFamily,
    );
    final loader = FontLoader(AppTextStyles.fontFamily);
    for (final font in (geist['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await expectLater(loader.load(), completes);
  });

  for (final brightness in Brightness.values) {
    testWidgets('every text theme style uses Geist in the ${brightness.name} '
        'theme', (tester) async {
      late ThemeData theme;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              theme = brightness == Brightness.dark
                  ? AppTheme.darkTheme(context)
                  : AppTheme.lightTheme(context);
              return const SizedBox();
            },
          ),
        ),
      );

      final styles = <String, TextStyle?>{
        'displayLarge': theme.textTheme.displayLarge,
        'headlineMedium': theme.textTheme.headlineMedium,
        'titleLarge': theme.textTheme.titleLarge,
        'titleMedium': theme.textTheme.titleMedium,
        'bodyLarge': theme.textTheme.bodyLarge,
        'bodyMedium': theme.textTheme.bodyMedium,
        'bodySmall': theme.textTheme.bodySmall,
        'labelLarge': theme.textTheme.labelLarge,
        'labelSmall': theme.textTheme.labelSmall,
        'appBarTitle': theme.appBarTheme.titleTextStyle,
      };
      for (final entry in styles.entries) {
        expect(
          entry.value?.fontFamily,
          AppTextStyles.fontFamily,
          reason: entry.key,
        );
      }
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('Cupertino widgets use Geist in the ${brightness.name} '
        'theme', (tester) async {
      late CupertinoTextThemeData cupertino;
      // As in main.dart: the app theme goes on the MaterialApp itself. A
      // nested Theme would reuse the Cupertino theme above it.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) => MaterialApp(
              theme: AppTheme.lightTheme(context),
              darkTheme: AppTheme.darkTheme(context),
              themeMode: brightness == Brightness.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              home: Builder(
                builder: (context) {
                  cupertino = CupertinoTheme.of(context).textTheme;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(cupertino.textStyle.fontFamily, AppTextStyles.fontFamily);
      expect(
        cupertino.dateTimePickerTextStyle.fontFamily,
        AppTextStyles.fontFamily,
      );
      expect(cupertino.pickerTextStyle.fontFamily, AppTextStyles.fontFamily);
    });
  }

  test('the legacy styles carry Geist, also inside a RichText', () {
    // A RichText does not inherit the theme font, so the style must name it.
    // ignore: deprecated_member_use_from_same_package
    expect(AppTextStyles.title.fontFamily, AppTextStyles.fontFamily);
    // ignore: deprecated_member_use_from_same_package
    expect(AppTextStyles.subtitle.fontFamily, AppTextStyles.fontFamily);
    // ignore: deprecated_member_use_from_same_package
    expect(AppTextStyles.value.fontFamily, AppTextStyles.fontFamily);
  });
}
