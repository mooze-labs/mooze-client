import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Paints [child] into an image of [size] logical pixels at [pixelRatio],
/// in a tree of its own, off the screen: nothing of it shows, and the app
/// keeps drawing as before.
///
/// [child] gets no ancestors: pass it the media query, the theme and the
/// localizations it needs. A part that loads later, such as an SVG, gets
/// [settle] to arrive: the tree builds and paints again each time one does.
Future<ui.Image> paintOffscreen({
  required ui.FlutterView view,
  required Widget child,
  required Size size,
  required double pixelRatio,
  Duration settle = const Duration(milliseconds: 800),
}) async {
  final boundary = RenderRepaintBoundary();
  final renderView = RenderView(
    view: view,
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(size),
      devicePixelRatio: pixelRatio,
    ),
    // The view gives its child exactly [size].
    child: boundary,
  );
  final pipeline = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final focus = FocusManager();
  var dirty = false;
  final build = BuildOwner(
    focusManager: focus,
    onBuildScheduled: () => dirty = true,
  );
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: child,
  ).attachToRenderTree(build);

  void paint() {
    build.buildScope(root);
    build.finalizeTree();
    pipeline
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
  }

  try {
    paint();
    final deadline = DateTime.now().add(settle);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!dirty) continue;
      dirty = false;
      paint();
    }
    return await boundary.toImage(pixelRatio: pixelRatio);
  } finally {
    // Unmounts the tree, so its states let go of what they hold.
    RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
    ).attachToRenderTree(build, root);
    build.finalizeTree();
    focus.dispose();
    // The pipeline lets go of its root before it goes.
    pipeline.rootNode = null;
    renderView.dispose();
    pipeline.dispose();
  }
}
