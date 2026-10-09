import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../routes.dart';
import 'events.dart';
import 'providers.dart';

class AnalyticsNavigation extends ConsumerStatefulWidget {
  const AnalyticsNavigation({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AnalyticsNavigation> createState() =>
      _AnalyticsNavigationState();
}

class _AnalyticsNavigationState extends ConsumerState<AnalyticsNavigation> {
  String? _lastScreen;
  @override
  void initState() {
    super.initState();
    router.routerDelegate.addListener(_track);
    // Startup is independent of the wallet boot path.
    Future.microtask(() async {
      if (!mounted) return;
      await ref.read(analyticsProvider).start();
      if (mounted) _track();
    });
  }

  void _track() {
    final analytics = ref.read(analyticsProvider);
    if (!analytics.enabled || analytics.busy) {
      _lastScreen = null;
      return;
    }
    final config = router.routerDelegate.currentConfiguration;
    final screen = config.isError ? null : screenForPath(config.uri.path);
    if (screen == _lastScreen) return;
    _lastScreen = screen;
    if (screen != null) analytics.track(AnalyticsEvent.screen(screen));
  }

  @override
  void dispose() {
    router.routerDelegate.removeListener(_track);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(analyticsProvider, (_, next) {
      scheduleMicrotask(() {
        if (mounted) _track();
      });
    });
    return widget.child;
  }
}
