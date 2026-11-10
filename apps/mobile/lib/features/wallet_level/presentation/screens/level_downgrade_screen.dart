import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/level_change_scaffold.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// Full-screen moment shown when the wallet drops to a lower level.
///
/// The medal of the old level turns slowly to the medal of the new level
/// and sinks a little, as its outer ring drifts away. A glass panel holds
/// a tip to win the level back. See [LevelChangeScaffold].
class LevelDowngradeScreen extends StatelessWidget {
  final int oldLevel;
  final int newLevel;

  const LevelDowngradeScreen({
    super.key,
    required this.oldLevel,
    required this.newLevel,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return LevelChangeScaffold(
      oldLevel: oldLevel,
      newLevel: newLevel,
      title: t.level_down_title,
      message: t.level_down_message,
      badge: t.level_down_badge,
      ornament: '↓',
      tip: t.level_down_tip,
      actionLabel: t.common_understood,
    );
  }
}
