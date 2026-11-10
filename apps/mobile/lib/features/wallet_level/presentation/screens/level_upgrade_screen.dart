import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/level_change_scaffold.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// Full-screen moment shown when the wallet reaches a higher level.
///
/// The medal of the old level spins up and shows the medal of the new
/// level, with a shockwave and two orbiting rings in the color of the new
/// level. See [LevelChangeScaffold].
class LevelUpgradeScreen extends StatelessWidget {
  final int oldLevel;
  final int newLevel;

  const LevelUpgradeScreen({
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
      title: t.level_up_title,
      message: t.level_up_message,
      badge: t.level_up_badge,
      ornament: '✦',
      actionLabel: t.common_continue,
    );
  }
}
