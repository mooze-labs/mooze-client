import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The state of the pull-to-refresh of a [RefreshScrollView].
///
/// The view draws no indicator of its own. A widget that listens to this
/// controller shows the pull and the refresh, such as the loading part of a
/// `StatusIsland`.
class PullRefreshController extends ChangeNotifier {
  double _progress = 0;
  bool _refreshing = false;

  /// A refresh can complete after the screen that owns the controller
  /// closed.
  bool _disposed = false;

  /// How far the pull has gone toward a refresh: 0 at rest, 1 when a
  /// release starts a refresh. It goes back to 0 on release.
  double get progress => _progress;

  /// A refresh runs, from the release until the refresh completes.
  bool get refreshing => _refreshing;

  void _set({double? progress, bool? refreshing}) {
    if (_disposed) return;
    final nextProgress = progress ?? _progress;
    final nextRefreshing = refreshing ?? _refreshing;
    if (nextProgress == _progress && nextRefreshing == _refreshing) return;
    _progress = nextProgress;
    _refreshing = nextRefreshing;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// A scrolling screen body with pull-to-refresh.
///
/// A drag down from the top pulls. [controller] reports how far, and a
/// release past [armDistance] runs [onRefresh]. A haptic marks the point
/// where a release refreshes. The content always scrolls, so a pull
/// works on short content too. The pull keeps the overscroll of the
/// platform: on iOS the content follows the finger and springs back to the
/// top. On Android the content stays, and the stretch of the overscroll
/// stays off during a pull.
///
/// The content sits in a sliver viewport, not in a [SingleChildScrollView].
/// The viewport of a [SingleChildScrollView] moves an overscrolled offset
/// back into range on every layout and keeps the scroll momentum. A refresh
/// starts while the content springs back, and new data then lays the
/// content out again: the offset jumped to the top, and the momentum of
/// the spring scrolled the page into the content. A sliver viewport keeps
/// the overscroll, so the spring ends at the top.
class RefreshScrollView extends StatefulWidget {
  const RefreshScrollView({
    super.key,
    required this.controller,
    required this.onRefresh,
    this.padding = EdgeInsets.zero,
    required this.child,
  });

  /// The pull distance at which a release refreshes.
  ///
  /// On iOS the distance is the overscroll that shows, after the
  /// resistance of the overscroll: the finger moves about twice as far.
  static const double armDistance = 96;

  /// The share of the finger travel that counts as pull where the platform
  /// reports the raw overscroll (Android). It matches the resistance of the
  /// iOS overscroll, so a pull is about as long on both platforms.
  static const double clampingDragRate = 0.5;

  final PullRefreshController controller;

  /// Runs on a release past [armDistance]. The refresh lasts until the
  /// future completes.
  final RefreshCallback onRefresh;

  /// Space around [child], inside the scrolling area.
  final EdgeInsetsGeometry padding;

  final Widget child;

  @override
  State<RefreshScrollView> createState() => _RefreshScrollViewState();
}

class _RefreshScrollViewState extends State<RefreshScrollView> {
  /// The pull distance of the drag in progress, or null without a pull.
  double? _pull;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical ||
        widget.controller.refreshing) {
      return false;
    }
    if (_pull == null) {
      // A pull starts with a drag at the top of the content.
      if (notification is ScrollStartNotification &&
          notification.dragDetails != null &&
          notification.metrics.extentBefore == 0) {
        _pull = 0;
      }
      return false;
    }
    switch (notification) {
      case ScrollUpdateNotification(dragDetails: null):
        // On iOS the content springs back after the release.
        _release();
      case ScrollUpdateNotification(:final scrollDelta?):
        _pullBy(-scrollDelta);
      case OverscrollNotification(:final overscroll):
        _pullBy(-overscroll * RefreshScrollView.clampingDragRate);
      case ScrollEndNotification():
        _release();
      default:
        break;
    }
    return false;
  }

  void _pullBy(double delta) {
    final pull = _pull! + delta;
    _pull = pull;
    final progress = (pull / RefreshScrollView.armDistance).clamp(0.0, 1.0);
    if (progress == 1 && widget.controller.progress < 1) {
      HapticFeedback.mediumImpact();
    }
    widget.controller._set(progress: progress);
  }

  void _release() {
    _pull = null;
    final controller = widget.controller;
    if (controller.progress < 1) {
      controller._set(progress: 0);
      return;
    }
    controller._set(progress: 0, refreshing: true);
    widget.onRefresh().whenComplete(() => controller._set(refreshing: false));
  }

  /// Keeps the Android stretch off while the content is pulled.
  bool _onOverscrollIndicator(OverscrollIndicatorNotification notification) {
    if (notification.depth != 0 || !notification.leading || _pull == null) {
      return false;
    }
    notification.disallowIndicator();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: _onOverscrollIndicator,
        child: CustomScrollView(
          // The tab pages share one route. The view stays off the primary
          // scroll controller, so the pages do not scroll together.
          primary: false,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: widget.padding,
              sliver: SliverToBoxAdapter(child: widget.child),
            ),
          ],
        ),
      ),
    );
  }
}
