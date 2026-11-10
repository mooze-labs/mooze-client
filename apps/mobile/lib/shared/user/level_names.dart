import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// The names of the wallet levels in the language of the app.
extension LevelNames on AppLocalizations {
  /// Returns the name of the level of [order]: 0 is Bronze, 1 Silver, 2
  /// Gold, and 3 Diamond. Any other order is Bronze, the first level.
  String levelName(int order) => switch (order) {
    1 => level_name_silver,
    2 => level_name_gold,
    3 => level_name_diamond,
    _ => level_name_bronze,
  };
}
