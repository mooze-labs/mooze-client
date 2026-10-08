import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  test('light adapter preserves all pre-migration colors', () {
    const scheme = AppColors.lightColorScheme;
    const extra = AppExtraColors.light;
    expect(scheme.primary.toARGB32(), 0xFFEA1E63, reason: 'primary');
    expect(scheme.onPrimary.toARGB32(), 0xFFFFFFFF, reason: 'onPrimary');
    expect(scheme.primaryContainer.toARGB32(), 0xFFFFD9E4, reason: 'primaryContainer');
    expect(scheme.onPrimaryContainer.toARGB32(), 0xFF3E0020, reason: 'onPrimaryContainer');
    expect(scheme.secondary.toARGB32(), 0xFF4B5563, reason: 'secondary');
    expect(scheme.onSecondary.toARGB32(), 0xFFFFFFFF, reason: 'onSecondary');
    expect(scheme.secondaryContainer.toARGB32(), 0xFFE2E4EA, reason: 'secondaryContainer');
    expect(scheme.onSecondaryContainer.toARGB32(), 0xFF1A1A2E, reason: 'onSecondaryContainer');
    expect(scheme.tertiary.toARGB32(), 0xFF16A34A, reason: 'tertiary');
    expect(scheme.onTertiary.toARGB32(), 0xFFFFFFFF, reason: 'onTertiary');
    expect(scheme.tertiaryContainer.toARGB32(), 0xFFB7F0C8, reason: 'tertiaryContainer');
    expect(scheme.onTertiaryContainer.toARGB32(), 0xFF002110, reason: 'onTertiaryContainer');
    expect(scheme.error.toARGB32(), 0xFFDC2626, reason: 'error');
    expect(scheme.onError.toARGB32(), 0xFFFFFFFF, reason: 'onError');
    expect(scheme.errorContainer.toARGB32(), 0xFFFFDAD6, reason: 'errorContainer');
    expect(scheme.onErrorContainer.toARGB32(), 0xFF410002, reason: 'onErrorContainer');
    expect(scheme.surface.toARGB32(), 0xFFF5F6FA, reason: 'surface');
    expect(scheme.onSurface.toARGB32(), 0xFF1A1A2E, reason: 'onSurface');
    expect(scheme.surfaceTint.toARGB32(), 0xFFEA1E63, reason: 'surfaceTint');
    expect(scheme.surfaceDim.toARGB32(), 0xFFE2E4EA, reason: 'surfaceDim');
    expect(scheme.surfaceBright.toARGB32(), 0xFFFFFFFF, reason: 'surfaceBright');
    expect(scheme.surfaceContainerLowest.toARGB32(), 0xFFFFFFFF, reason: 'surfaceContainerLowest');
    expect(scheme.surfaceContainerLow.toARGB32(), 0xFFF5F6FA, reason: 'surfaceContainerLow');
    expect(scheme.surfaceContainer.toARGB32(), 0xFFE2E4EA, reason: 'surfaceContainer');
    expect(scheme.surfaceContainerHigh.toARGB32(), 0xFFE2E4EA, reason: 'surfaceContainerHigh');
    expect(scheme.surfaceContainerHighest.toARGB32(), 0xFFE2E4EA, reason: 'surfaceContainerHighest');
    expect(scheme.outline.toARGB32(), 0xFFB8BCC6, reason: 'outline');
    expect(scheme.outlineVariant.toARGB32(), 0xFFE2E4EA, reason: 'outlineVariant');
    expect(scheme.inverseSurface.toARGB32(), 0xFF1A1A2E, reason: 'inverseSurface');
    expect(scheme.onInverseSurface.toARGB32(), 0xFFF5F6FA, reason: 'onInverseSurface');
    expect(scheme.inversePrimary.toARGB32(), 0xFFFFB0C8, reason: 'inversePrimary');
    expect(scheme.scrim.toARGB32(), 0xFF000000, reason: 'scrim');
    expect(scheme.shadow.toARGB32(), 0xFF000000, reason: 'shadow');
    expect(extra.warning.toARGB32(), 0xFFE65100, reason: 'warning');
    expect(extra.onWarning.toARGB32(), 0xFFF57C00, reason: 'onWarning');
    expect(extra.textSecondary.toARGB32(), 0xFF5C5F72, reason: 'textSecondary');
    expect(extra.textTertiary.toARGB32(), 0xFF6B6B6B, reason: 'textTertiary');
    expect(extra.textQuartiary.toARGB32(), 0xFF8A8A8A, reason: 'textQuartiary');
    expect(extra.textQuintary.toARGB32(), 0xFF7B7595, reason: 'textQuintary');
    expect(extra.shimmerBase.toARGB32(), 0xFFBDBDBD, reason: 'shimmerBase');
    expect(extra.shimmerHighlight.toARGB32(), 0xFFE8E8E8, reason: 'shimmerHighlight');
    expect(extra.navBarFabBackground.toARGB32(), 0xFFAD1457, reason: 'navBarFabBackground');
    expect(extra.pinBackground.toARGB32(), 0xFFF5F5F5, reason: 'pinBackground');
    expect(extra.recoveryPhraseBackground.toARGB32(), 0xFFF0EEF5, reason: 'recoveryPhraseBackground');
    expect(extra.primaryIconColor.toARGB32(), 0xFF5B7A9A, reason: 'primaryIconColor');
    expect(extra.menuIconColor.toARGB32(), 0xFF475569, reason: 'menuIconColor');
    expect(extra.editColor.toARGB32(), 0xFFFF9800, reason: 'editColor');
    expect(extra.actionButtonBackground.toARGB32(), 0xFFD1D5DB, reason: 'actionButtonBackground');
  });
  test('dark adapter preserves all pre-migration colors', () {
    const scheme = AppColors.darkColorScheme;
    const extra = AppExtraColors.dark;
    expect(scheme.primary.toARGB32(), 0xFFEA1E63, reason: 'primary');
    expect(scheme.onPrimary.toARGB32(), 0xFFFFFFFF, reason: 'onPrimary');
    expect(scheme.primaryContainer.toARGB32(), 0xFF4A0E2A, reason: 'primaryContainer');
    expect(scheme.onPrimaryContainer.toARGB32(), 0xFFFFD9E4, reason: 'onPrimaryContainer');
    expect(scheme.secondary.toARGB32(), 0xFF212121, reason: 'secondary');
    expect(scheme.onSecondary.toARGB32(), 0x99FFFFFF, reason: 'onSecondary');
    expect(scheme.secondaryContainer.toARGB32(), 0xFF383838, reason: 'secondaryContainer');
    expect(scheme.onSecondaryContainer.toARGB32(), 0xFFE6E1E5, reason: 'onSecondaryContainer');
    expect(scheme.tertiary.toARGB32(), 0xFF32B153, reason: 'tertiary');
    expect(scheme.onTertiary.toARGB32(), 0xFFFFFFFF, reason: 'onTertiary');
    expect(scheme.tertiaryContainer.toARGB32(), 0xFF0F3A1C, reason: 'tertiaryContainer');
    expect(scheme.onTertiaryContainer.toARGB32(), 0xFFB7F397, reason: 'onTertiaryContainer');
    expect(scheme.error.toARGB32(), 0xFFD73131, reason: 'error');
    expect(scheme.onError.toARGB32(), 0xFFFFFFFF, reason: 'onError');
    expect(scheme.errorContainer.toARGB32(), 0xFF410E0B, reason: 'errorContainer');
    expect(scheme.onErrorContainer.toARGB32(), 0xFFF2B8B5, reason: 'onErrorContainer');
    expect(scheme.surface.toARGB32(), 0xFF141722, reason: 'surface');
    expect(scheme.onSurface.toARGB32(), 0xFFFFFFFF, reason: 'onSurface');
    expect(scheme.surfaceTint.toARGB32(), 0xFFEA1E63, reason: 'surfaceTint');
    expect(scheme.surfaceDim.toARGB32(), 0xFF000000, reason: 'surfaceDim');
    expect(scheme.surfaceBright.toARGB32(), 0xFF1F1F1F, reason: 'surfaceBright');
    expect(scheme.surfaceContainerLowest.toARGB32(), 0xFF0A0A0A, reason: 'surfaceContainerLowest');
    expect(scheme.surfaceContainerLow.toARGB32(), 0xFF111111, reason: 'surfaceContainerLow');
    expect(scheme.surfaceContainer.toARGB32(), 0xFF141722, reason: 'surfaceContainer');
    expect(scheme.surfaceContainerHigh.toARGB32(), 0xFF1C1C1C, reason: 'surfaceContainerHigh');
    expect(scheme.surfaceContainerHighest.toARGB32(), 0xFF26252A, reason: 'surfaceContainerHighest');
    expect(scheme.outline.toARGB32(), 0xFF2D2E2A, reason: 'outline');
    expect(scheme.outlineVariant.toARGB32(), 0xFF7C7C7C, reason: 'outlineVariant');
    expect(scheme.inverseSurface.toARGB32(), 0xFFE6E1E5, reason: 'inverseSurface');
    expect(scheme.onInverseSurface.toARGB32(), 0xFF313033, reason: 'onInverseSurface');
    expect(scheme.inversePrimary.toARGB32(), 0xFF9F4052, reason: 'inversePrimary');
    expect(scheme.scrim.toARGB32(), 0xFF000000, reason: 'scrim');
    expect(scheme.shadow.toARGB32(), 0xFF000000, reason: 'shadow');
    expect(extra.warning.toARGB32(), 0xFFFB8C00, reason: 'warning');
    expect(extra.onWarning.toARGB32(), 0xFFFFB74D, reason: 'onWarning');
    expect(extra.textSecondary.toARGB32(), 0xFF9194A6, reason: 'textSecondary');
    expect(extra.textTertiary.toARGB32(), 0xFF7C7C7C, reason: 'textTertiary');
    expect(extra.textQuartiary.toARGB32(), 0xFFC2C2C2, reason: 'textQuartiary');
    expect(extra.textQuintary.toARGB32(), 0xFFA6A0BB, reason: 'textQuintary');
    expect(extra.shimmerBase.toARGB32(), 0xFF757575, reason: 'shimmerBase');
    expect(extra.shimmerHighlight.toARGB32(), 0xFFBDBDBD, reason: 'shimmerHighlight');
    expect(extra.navBarFabBackground.toARGB32(), 0xFFAD1457, reason: 'navBarFabBackground');
    expect(extra.pinBackground.toARGB32(), 0xFF191818, reason: 'pinBackground');
    expect(extra.recoveryPhraseBackground.toARGB32(), 0xFF1C1924, reason: 'recoveryPhraseBackground');
    expect(extra.primaryIconColor.toARGB32(), 0xFF9DB2CE, reason: 'primaryIconColor');
    expect(extra.menuIconColor.toARGB32(), 0xFFB0BAD0, reason: 'menuIconColor');
    expect(extra.editColor.toARGB32(), 0xFFFFAB40, reason: 'editColor');
    expect(extra.actionButtonBackground.toARGB32(), 0xFF2B2D33, reason: 'actionButtonBackground');
  });
  testWidgets('scaffold and card roles follow selected appearance', (tester) async {
    for (final dark in [false, true]) {
      await tester.pumpWidget(Builder(builder: (context) => MaterialApp(
        theme: AppTheme.lightTheme(context), darkTheme: AppTheme.darkTheme(context),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: const Scaffold(body: Card(child: Text('Wallet'))),
      )));
      await tester.pumpAndSettle();
      final theme = Theme.of(tester.element(find.byType(Card)));
      expect(theme.scaffoldBackgroundColor.toARGB32(), dark ? 0xFF000000 : 0xFFE2E4EA);
      expect(theme.cardTheme.color!.toARGB32(), dark ? 0xFF0A0A0A : 0xFFFFFFFF);
    }
  });
}
