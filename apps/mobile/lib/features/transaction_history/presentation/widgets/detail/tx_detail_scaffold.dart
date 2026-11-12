import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/motion/staggered_entrance.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Page shell of the transaction detail screen.
///
/// The page is the backdrop of the main screens with the detail artwork on
/// top: a soft brand light behind the hero and thin light sweeps across the
/// upper screen. The app bar paints its slice of the same background, so
/// the bar and the page read as one surface without a seam.
///
/// The page fills the screen in two zones. The [hero] zone takes the free
/// height and centers the hero in it, so a short transaction has no blank
/// lower half. The [sections] stack below it as one group, near the thumb.
/// A long transaction scrolls, and the hero zone then shrinks to its
/// content. The page enters with a short staggered fade-and-rise, once per
/// transaction in an app session.
class TxDetailScaffold extends StatelessWidget {
  const TxDetailScaffold({
    super.key,
    required this.title,
    required this.entranceKey,
    required this.hero,
    required this.sections,
    this.actions,
  });

  final String title;

  /// Actions of the app bar, such as a menu.
  final List<Widget>? actions;

  /// Identifies the transaction, so its entrance plays once per session.
  final Object entranceKey;

  final Widget hero;

  final List<Widget> sections;

  /// Side margin of the content.
  static const double gutter = 20;

  /// Space above and below the hero when the zone has no free height.
  static const double _heroInset = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: context.colors.textPrimary,
        actions: actions,
        // The bar starts at the top of the screen, like the page layer, so
        // both paint the same background.
        flexibleSpace: const _PageBackground(),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _PageBackground()),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  // The padding sits inside the sliver: a trailing
                  // SliverPadding would add to the filled height and make a
                  // short page scroll.
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      0,
                      gutter,
                      16 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: _heroInset,
                            ),
                            // The outer column gives the entrance an open
                            // height, so it sizes to the hero and the hero
                            // centers in the zone.
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                StaggeredEntrance(
                                  sessionKey: ('hero', entranceKey),
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  sections: [hero],
                                ),
                              ],
                            ),
                          ),
                        ),
                        StaggeredEntrance(
                          sessionKey: entranceKey,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          sections: sections,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The screen backdrop with the detail artwork on top, both measured from
/// the top of the screen.
class _PageBackground extends StatelessWidget {
  const _PageBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: Stack(fit: StackFit.expand, children: [const AppBackdrop()]),
    );
  }
}
