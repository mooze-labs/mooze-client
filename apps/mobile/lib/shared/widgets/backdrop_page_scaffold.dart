import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';

/// Page shell of a secondary screen, such as a settings or a list screen.
///
/// The backdrop of the main screens fills the page behind a clear app bar.
/// The bar paints its slice of the backdrop, so the bar and the page read
/// as one surface. Content goes on the backdrop in [GlassPanel]s.
///
/// [body] starts below the app bar and the status bar. It reaches the
/// bottom edge, so a scrolling list ends with its own bottom padding.
class BackdropPageScaffold extends StatelessWidget {
  const BackdropPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.bottomAction,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  /// Replaces the back button, for example to pop through a guard.
  final Widget? leading;

  /// Main action of the screen, pinned above the bottom edge.
  final Widget? bottomAction;

  final Widget? floatingActionButton;

  /// Side margin of the content.
  static const double gutter = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BackdropAppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
      ),
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            bottom: bottomAction != null,
            child: Column(
              children: [
                Expanded(child: body),
                if (bottomAction != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(gutter, 8, gutter, 12),
                    child: bottomAction,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
