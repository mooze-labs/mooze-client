import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/routes.dart';
import 'package:mooze_mobile/shared/user/providers/level_change_provider.dart';

class LevelChangeListener extends ConsumerStatefulWidget {
  final Widget child;

  const LevelChangeListener({super.key, required this.child});

  @override
  ConsumerState<LevelChangeListener> createState() =>
      _LevelChangeListenerState();
}

class _LevelChangeListenerState extends ConsumerState<LevelChangeListener> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {

    ref.listen(levelChangeStreamProvider, (previous, next) {

      next.when(
        data: (levelChange) {

          if (_isNavigating) {
            return;
          }

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await Future.delayed(const Duration(milliseconds: 500));

            if (!mounted) {
              return;
            }

            try {
              final currentLocation =
                  router.routerDelegate.currentConfiguration.uri.path;

              if (currentLocation == '/level-upgrade' ||
                  currentLocation == '/level-downgrade') {
                return;
              }

              _isNavigating = true;

              if (levelChange.isUpgrade) {
                await router.push(
                  '/level-upgrade?oldLevel=${levelChange.oldLevel}&newLevel=${levelChange.newLevel}',
                );
              } else if (levelChange.isDowngrade) {
                await router.push(
                  '/level-downgrade?oldLevel=${levelChange.oldLevel}&newLevel=${levelChange.newLevel}',
                );
              } 
              if (mounted) {
                _isNavigating = false;
              }
            } catch (e) {
              _isNavigating = false;
            }
          });
        },
        loading: () => print('[LISTENER] Loading...'),
        error: (error, stack) => print('[LISTENER] : Error - $error'),
      );
    });

    return widget.child;
  }
}
