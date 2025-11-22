import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/user/providers/level_change_provider.dart';

class LevelChangeListener extends ConsumerStatefulWidget {
  final Widget child;

  const LevelChangeListener({super.key, required this.child});

  @override
  ConsumerState<LevelChangeListener> createState() =>
      _LevelChangeListenerState();
}

class _LevelChangeListenerState extends ConsumerState<LevelChangeListener> {
  @override
  Widget build(BuildContext context) {
    ref.listen(levelChangeStreamProvider, (previous, next) {
      next.whenData((levelChange) {
        final currentRoute = GoRouterState.of(context).uri.path;
        if (currentRoute == '/level-upgrade' ||
            currentRoute == '/level-downgrade') {
          return;
        }

        if (levelChange.isUpgrade) {
          context.go(
            '/level-upgrade?oldLevel=${levelChange.oldLevel}&newLevel=${levelChange.newLevel}',
          );
        } else if (levelChange.isDowngrade) {
          context.go(
            '/level-downgrade?oldLevel=${levelChange.oldLevel}&newLevel=${levelChange.newLevel}',
          );
        }
      });
    });

    return widget.child;
  }
}
