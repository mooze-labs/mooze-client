import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// An action of a [GlassMenuButton].
class GlassMenuItem {
  const GlassMenuItem({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.destructive = false,
  });

  final IconData icon;
  final String label;

  /// Runs after the menu has closed.
  final VoidCallback onSelected;

  /// Shows the item in the negative color, for an action that cannot be
  /// undone, such as a revoke.
  final bool destructive;
}

/// The "more" button of an app bar. Its menu opens as a floating panel of
/// opaque Liquid Glass, as the sheets and dialogs of the app.
///
/// The panel hangs from the button, at the end of the bar. It grows from
/// the button and fades in over [Motion.durationEmphasis], and closes over
/// [Motion.durationExit]. With reduced motion, it opens and closes at once.
/// A tap outside or the system back closes it. A chosen item runs once the
/// panel has closed, so a sheet that it opens does not stack over a closing
/// menu.
class GlassMenuButton extends StatelessWidget {
  const GlassMenuButton({
    super.key,
    required this.tooltip,
    required this.items,
  });

  /// Name of the button for screen readers, and of the menu it opens.
  final String tooltip;

  final List<GlassMenuItem> items;

  Future<void> _open(BuildContext context) async {
    final navigator = Navigator.of(context);
    final button = context.findRenderObject()! as RenderBox;
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final anchor =
        button.localToGlobal(Offset.zero, ancestor: overlay) & button.size;
    final route = _GlassMenuRoute(
      anchor: anchor,
      items: items,
      label: tooltip,
      reduced: Motion.isReduced(context),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    );
    // The push ends when the menu starts to close. The action waits until
    // the panel is gone.
    final chosen = await navigator.push(route);
    await route.completed;
    chosen?.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      // The builder context is the button, so the menu hangs from it.
      builder: (context) => IconButton(
        tooltip: tooltip,
        icon: Icon(Icons.more_vert_rounded, color: context.colors.textPrimary),
        onPressed: () => _open(context),
      ),
    );
  }
}

class _GlassMenuRoute extends PopupRoute<GlassMenuItem> {
  _GlassMenuRoute({
    required this.anchor,
    required this.items,
    required this.label,
    required this.reduced,
    required this.barrierLabel,
  });

  /// Where the button is, in the coordinates of the navigator.
  final Rect anchor;
  final List<GlassMenuItem> items;
  final String label;
  final bool reduced;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration =>
      reduced ? Duration.zero : Motion.durationEmphasis;

  @override
  Duration get reverseTransitionDuration =>
      reduced ? Duration.zero : Motion.durationExit;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The panel grows from the corner under the button.
    final origin = rtl ? Alignment.topLeft : Alignment.topRight;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.curveEnter,
      reverseCurve: Motion.curveExit,
    );
    return CustomSingleChildLayout(
      delegate: _MenuLayout(
        anchor: anchor,
        padding: MediaQuery.paddingOf(context),
        rtl: rtl,
      ),
      child: FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(curved),
          alignment: origin,
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: label,
            child: _GlassMenuPanel(items: items),
          ),
        ),
      ),
    );
  }
}

/// Places the panel under the button, its end edge on the end edge of the
/// button, inside the safe area of the screen. Where there is no room
/// below, the panel opens above the button.
class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout({required this.anchor, required this.padding, required this.rtl});

  final Rect anchor;
  final EdgeInsets padding;
  final bool rtl;

  /// Smallest space between the panel and the edges of the screen.
  static const double margin = 8;

  /// Space between the button and the panel.
  static const double gap = 4;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: math.max(0, constraints.maxWidth - 2 * margin),
      maxHeight: math.max(
        0,
        constraints.maxHeight - padding.vertical - 2 * margin,
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = (rtl ? anchor.left : anchor.right - childSize.width)
        .clamp(margin, math.max(margin, size.width - childSize.width - margin))
        .toDouble();
    final bottomLimit = size.height - padding.bottom - margin;
    var y = anchor.bottom + gap;
    if (y + childSize.height > bottomLimit) {
      y = anchor.top - gap - childSize.height;
    }
    y = math.max(y, padding.top + margin);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuLayout old) =>
      anchor != old.anchor || padding != old.padding || rtl != old.rtl;
}

class _GlassMenuPanel extends StatelessWidget {
  const _GlassMenuPanel({required this.items});

  final List<GlassMenuItem> items;

  /// Width limits of the panel.
  static const double minWidth = 200;
  static const double maxWidth = 280;

  @override
  Widget build(BuildContext context) {
    final hairline = AppSurfaces.hairline(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
      child: IntrinsicWidth(
        child: LiquidGlass(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          // An overlay: opaque, so the content behind it does not show
          // through the text, and no blur to pay for.
          blurBackdrop: false,
          opaque: true,
          child: Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, item) in items.indexed) ...[
                    if (index > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: hairline,
                      ),
                    _GlassMenuTile(item: item),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassMenuTile extends StatelessWidget {
  const _GlassMenuTile({required this.item});

  final GlassMenuItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.destructive
        ? context.colors.negativeColor
        : context.colors.textPrimary;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(item),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
