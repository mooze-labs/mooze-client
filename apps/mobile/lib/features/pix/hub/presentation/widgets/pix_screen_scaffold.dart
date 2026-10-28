import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Page shell shared by the Pix hub screens.
///
/// Every screen of the area repeats the same structure: the backdrop of the
/// main screens behind a clear app bar, the screen name as a large
/// left-aligned title, the content on a 20 pt gutter and, when the screen
/// has a main action, a button pinned to the bottom. Keeping it in one
/// widget is what makes the flows look alike.
///
/// The content fades and rises in once when the screen opens, over
/// [Motion.durationBase]. It never blocks a tap. With reduced motion it
/// appears at once.
class PixScreenScaffold extends StatelessWidget {
  /// Large title shown at the top of the content.
  final String title;

  /// Name of the flow, shown in the app bar above [title].
  ///
  /// The send flow uses it so every step states which flow it belongs to.
  final String? appBarTitle;

  /// Optional line below the title.
  final String? subtitle;

  /// Content of the scrollable area, below the title.
  final List<Widget> children;

  /// Main action of the screen, pinned above the bottom edge.
  final Widget? bottomAction;

  /// Extra actions for the app bar.
  final List<Widget>? appBarActions;

  /// Pull-to-refresh handler. Omit it when the screen has nothing to reload.
  final Future<void> Function()? onRefresh;

  const PixScreenScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.appBarTitle,
    this.bottomAction,
    this.appBarActions,
    this.onRefresh,
  });

  /// Side margin of the content.
  static const double gutter = 20;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      // A pull-to-refresh needs a list that always scrolls.
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        gutter,
        8,
        gutter,
        bottomAction == null ? 32 : 16,
      ),
      children: [
        PixScreenTitle(title: title, subtitle: subtitle),
        const SizedBox(height: 28),
        ...children,
      ],
    );

    return Scaffold(
      // The app bar is clear and paints its slice of the backdrop, so the
      // bar and the page read as one surface.
      extendBodyBehindAppBar: true,
      appBar: BackdropAppBar(
        title: appBarTitle == null ? null : Text(appBarTitle!),
        actions: appBarActions,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          // A tap outside a field closes the keyboard on every screen of
          // the area.
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: _ContentEntrance(
                child: Column(
                  children: [
                    Expanded(
                      child: onRefresh == null
                          ? list
                          : RefreshIndicator(
                              onRefresh: onRefresh!,
                              child: list,
                            ),
                    ),
                    if (bottomAction != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          gutter,
                          8,
                          gutter,
                          12,
                        ),
                        child: bottomAction!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The large title and the optional subtitle of a Pix screen.
///
/// [PixScreenScaffold] shows it at the top of the content. A screen with its
/// own layout, for example a state screen, can use it alone.
class PixScreenTitle extends StatelessWidget {
  const PixScreenTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.textAlign = TextAlign.start,
  });

  final String title;
  final String? subtitle;
  final TextAlign textAlign;

  /// Largest text scale of the title.
  static const double _maxTitleScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final crossAxis = textAlign == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: textAlign,
            // A large title grows with the system text size up to 150%, as
            // the platform large titles do. Above that, long words would
            // break inside the word on a narrow screen. Body text keeps the
            // full scale.
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: _maxTitleScale),
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

/// Fades and raises the content once, when the screen opens.
class _ContentEntrance extends StatefulWidget {
  const _ContentEntrance({required this.child});

  final Widget child;

  @override
  State<_ContentEntrance> createState() => _ContentEntranceState();
}

class _ContentEntranceState extends State<_ContentEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationBase,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Motion.curveEnter,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      if (Motion.isReduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(animation: _animation, child: widget.child);
  }
}
