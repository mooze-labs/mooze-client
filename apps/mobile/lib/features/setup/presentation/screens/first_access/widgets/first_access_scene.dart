import 'dart:math' as math;
import 'dart:ui' as ui show Gradient;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/first_access/providers/terms_acceptance_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/glyph_colors.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Where the door of the first access is in its motion.
@immutable
class DoorMotion {
  const DoorMotion({
    this.time = 1,
    this.open = 0,
    this.opening = true,
    this.orbit = 1,
  });

  /// The door at rest, ajar.
  static const rest = DoorMotion();

  /// The point of the opening where the light breaks out: the flash, the
  /// shockwave, and the knock leave, and the assets start to come out.
  static const double peak = 0.38;

  /// Time since the screen showed, from 0 to 1 over [Motion.durationAmbient]
  /// forward and back. The door enters first, over
  /// [Motion.durationOnboardingScene], then drifts. At 1 it rests.
  final double time;

  /// How open the door is, from 0, ajar, to 1, open.
  final double open;

  /// Whether the door is opening or open, not shutting.
  final bool opening;

  /// Time of the assets since the door last opened, in units of
  /// [Motion.durationAmbient] forward and back, as the time of the first
  /// page of the onboarding. It runs on for as long as the door is open: 1
  /// is the assets out and still.
  final double orbit;

  /// The share of the time of a scene that its entrance takes:
  /// [Motion.durationOnboardingScene].
  static double get _entranceShare =>
      Motion.durationOnboardingScene.inMicroseconds /
      (Motion.durationAmbient * 2).inMicroseconds;

  /// The entrance, from 0 to 1.
  double get entrance => stageProgress(time, 0, _entranceShare);

  /// The assets coming out of the Mooze coin, from 0 to 1, over the
  /// entrance of an onboarding scene.
  double get arrival => stageProgress(orbit, 0, _entranceShare);

  /// The sway of the assets, from -1 to 1: one way, back, the other way,
  /// and on, as long as the door is open. Its first half is the drift of
  /// an onboarding scene.
  double get sway => math.sin(math.pi * orbit);

  /// A slow sway that rises and falls back to 0.
  double get drift => math.sin(math.pi * time);

  /// How far the door has swung, from ajar to open.
  double get swing =>
      Curves.easeInOutCubic.transform(stageProgress(open, 0, 0.6));

  /// How far the assets are out of the doorway: they come out from the
  /// peak, and go back in as the door shuts.
  double get presence =>
      Curves.easeOut.transform(stageProgress(open, peak, 0.9));

  /// The flash of the peak, from 0 to 1, or null when it does not show. It
  /// plays only on the way in: the door shuts quietly.
  double? get flash =>
      opening && open >= peak ? stageProgress(open, peak, peak + 0.22) : null;

  /// The ring of light that leaves the doorway at the peak, on the way in.
  double get shockwave => opening ? stageProgress(open, peak, 1) : 0;

  /// The timeline of the sparkles around the assets, on the way in.
  double get sparkle => opening ? open : 0;

  @override
  String toString() =>
      'DoorMotion(time: $time, open: $open, opening: $opening, '
      'orbit: $orbit)';
}

/// The art of the first access: a door in an arch, the way in to the
/// wallet.
///
/// A line of light draws the arch, and the door stands ajar with light
/// behind it. When the terms are accepted, the door swings in, the light
/// spills out on the floor toward the actions, and with a knock at the peak
/// the assets come out of the doorway: the coins of the assets, in their
/// own colors, spiral out of the Mooze coin to an orbit in front of the
/// door, after the beats of the first page of the onboarding, and sway back
/// and forth for as long as the door is open. When the terms are not
/// accepted, the assets go back in and the door shuts with a tap, and
/// nothing moves. A screen shown again with the terms accepted opens with
/// its door open and its assets out. Under reduced motion, the door rests
/// at once and opens at once, and the assets stay still.
class FirstAccessScene extends ConsumerStatefulWidget {
  const FirstAccessScene({super.key});

  @override
  ConsumerState<FirstAccessScene> createState() => _FirstAccessSceneState();
}

class _FirstAccessSceneState extends ConsumerState<FirstAccessScene>
    with TickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: Motion.durationAmbient * 2,
  );

  late final AnimationController _door;

  /// The clock of the assets, from the peak of each opening: see
  /// [DoorMotion.orbit]. It runs while the door is open.
  late final AnimationController _orbit = AnimationController.unbounded(
    vsync: this,
  );

  /// Whether the opening in progress owes its knock: it started before the
  /// peak. A door that turns back after the peak does not knock twice.
  bool _knockDue = false;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _door = AnimationController(
      vsync: this,
      duration: Motion.durationDoorOpen,
      reverseDuration: Motion.durationSlow,
      value: ref.read(termsAcceptanceProvider) ? 1 : 0,
    )..addListener(_onDoorMove);
    // An open door shows its assets out.
    _orbit.value = _door.value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.isReduced(context)) {
      _clock.value = 1;
      return;
    }
    if (_door.isCompleted) _runOrbit(from: 1);
    // The entrance starts once the route is in place.
    final route = ModalRoute.of(context)?.animation;
    if (route == null || route.isCompleted) {
      _clock.forward();
      return;
    }
    void start(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      route.removeStatusListener(start);
      if (mounted) _clock.forward();
    }

    route.addStatusListener(start);
  }

  @override
  void dispose() {
    _clock.dispose();
    _door.dispose();
    _orbit.dispose();
    super.dispose();
  }

  void _onTermsChanged(bool? previous, bool accepted) {
    if (Motion.isReduced(context)) {
      _door.value = accepted ? 1 : 0;
      _orbit.value = _door.value;
      HapticFeedback.lightImpact();
      return;
    }
    if (accepted) {
      _knockDue = _door.value < DoorMotion.peak;
      _door.forward();
      return;
    }
    _knockDue = false;
    // A door opened again before it shuts cancels the tap: the future of a
    // canceled animation never completes.
    _door.reverse().then((_) {
      if (!mounted) return;
      // The assets are in: their clock stops until the next opening.
      _orbit.value = 0;
      HapticFeedback.lightImpact();
    });
  }

  void _onDoorMove() {
    if (!_knockDue || _door.value < DoorMotion.peak) return;
    _knockDue = false;
    HapticFeedback.mediumImpact();
    _runOrbit(from: 0);
  }

  void _runOrbit({required double from}) => _orbit.animateWith(
    _EndlessTime(from: from, unit: Motion.durationAmbient * 2),
  );

  @override
  Widget build(BuildContext context) {
    ref.listen(termsAcceptanceProvider, _onTermsChanged);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_clock, _door, _orbit]),
        builder: (context, _) => FirstAccessSceneView(
          motion: DoorMotion(
            time: _clock.value,
            open: _door.value,
            opening: _door.status.isForwardOrCompleted,
            orbit: _orbit.value,
          ),
        ),
      ),
    );
  }
}

/// Time that runs on, from [from], in units of [unit].
class _EndlessTime extends Simulation {
  _EndlessTime({required this.from, required Duration unit})
    : _seconds = unit.inMicroseconds / Duration.microsecondsPerSecond;

  final double from;
  final double _seconds;

  @override
  double x(double time) => from + time / _seconds;

  @override
  double dx(double time) => 1 / _seconds;

  @override
  bool isDone(double time) => false;
}

/// The door of the first access at a [motion], in the brand pink and the
/// colors of the [StagePalette], like the onboarding scenes. It is
/// decorative: screen readers skip it.
class FirstAccessSceneView extends StatelessWidget {
  const FirstAccessSceneView({super.key, required this.motion});

  final DoorMotion motion;

  /// The Mooze wordmark on the face of the door.
  static const _wordmark = 'assets/logos/logo_primary.svg';

  /// The glyph of the Mooze coin among the assets.
  static const _moozeGlyph = 'assets/images/onboarding/mooze_m.svg';

  @override
  Widget build(BuildContext context) {
    final look = _Look(
      brand: context.colors.primaryColor,
      palette: StagePalette.of(context),
      shadow: context.colorScheme.shadow,
    );
    // The shockwave crosses the screen.
    final reach = MediaQuery.sizeOf(context).longestSide * 0.6;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final door = _Door.fit(constraints.biggest);
          if (door == null) return const SizedBox.expand();
          return SizedBox.fromSize(
            size: constraints.biggest,
            child: Stack(
              clipBehavior: Clip.none,
              children: _scene(look, door, constraints.biggest, motion, reach),
            ),
          );
        },
      ),
    );
  }
}

/// The colors of the scene.
class _Look {
  const _Look({
    required this.brand,
    required this.palette,
    required this.shadow,
  });

  final Color brand;
  final StagePalette palette;

  /// The shade of the door as it turns away from the light.
  final Color shadow;

  Color get light => palette.highlight(brand);

  StageEffects effects(Canvas canvas, double radius) =>
      StageEffects(canvas, tint: brand, light: light, radius: radius);

  Color metal(double tint) =>
      Color.alphaBlend(brand.withValues(alpha: tint), palette.base);

  @override
  bool operator ==(Object other) =>
      other is _Look &&
      other.brand == brand &&
      other.palette == palette &&
      other.shadow == shadow;

  @override
  int get hashCode => Object.hash(brand, palette, shadow);
}

/// Where the door stands on a stage.
class _Door {
  const _Door(this.rect);

  /// Width of the doorway over its height.
  static const double aspect = 0.62;

  /// How far the door stands ajar, in radians: a seam of light.
  static const double ajar = 0.16;

  /// How far it swings in when open: past a right angle, out of sight
  /// behind the jamb, so the doorway is clear.
  static const double wide = 1.85;

  /// Strength of the perspective, as in a stage token.
  static const double perspective = 0.0015;

  /// The door on a stage of [size], or null when the stage has no room for
  /// it, as with large text.
  static _Door? fit(Size size) {
    if (!size.isFinite) return null;
    final width = math.min(size.width * 0.54, size.height * 0.78 * aspect);
    if (width < 32) return null;
    final height = width / aspect;
    // Lower room for the light on the floor.
    final top = (size.height - height) * 0.3;
    return _Door(Rect.fromLTWH((size.width - width) / 2, top, width, height));
  }

  /// The doorway.
  final Rect rect;

  double get width => rect.width;
  double get height => rect.height;
  Offset get center => rect.center;

  /// Width of the frame around the doorway.
  double get frame => width * 0.09;

  RRect get doorway => _arch(rect);

  RRect get outer => _arch(
    Rect.fromLTRB(
      rect.left - frame,
      rect.top - frame,
      rect.right + frame,
      rect.bottom,
    ),
  );

  /// The outer edge of the frame, from its foot on the left, over the top,
  /// to its foot on the right.
  Path get outline {
    final box = outer.outerRect;
    final radius = box.width / 2;
    return Path()
      ..moveTo(box.left, box.bottom)
      ..lineTo(box.left, box.top + radius)
      ..arcToPoint(
        Offset(box.right, box.top + radius),
        radius: Radius.circular(radius),
      )
      ..lineTo(box.right, box.bottom);
  }

  /// Where the free edge of the door meets the floor when the door has
  /// turned in by [angle], as the perspective of [_Leaf] shows it.
  /// Once out of sight, the door leaves the whole doorway open.
  double footOfEdge(double angle) {
    final depth = width * math.sin(angle);
    final x = -width / 2 + width * math.cos(angle);
    return math.max(rect.left, center.dx + x / (1 + perspective * depth));
  }

  static RRect _arch(Rect rect) => RRect.fromRectAndCorners(
    rect,
    topLeft: Radius.circular(rect.width / 2),
    topRight: Radius.circular(rect.width / 2),
  );
}

List<Widget> _scene(
  _Look look,
  _Door door,
  Size stage,
  DoorMotion motion,
  double reach,
) {
  final e = motion.entrance;
  // A line of light draws the frame; the frame and the door fill in; the
  // light comes on behind the door.
  final trace = Curves.easeInOutCubic.transform(stageProgress(e, 0, 0.5));
  final build = Curves.easeOut.transform(stageProgress(e, 0.3, 0.65));
  final lit = Curves.easeOut.transform(stageProgress(e, 0.45, 0.85));
  // The door breathes while ajar, and its seam with it.
  final angle = lerpDouble(
    _Door.ajar * (1 + 0.5 * motion.drift),
    _Door.wide,
    motion.swing,
  )!;
  final flood = Curves.easeOut.transform(stageProgress(motion.open, 0, 0.5));
  final glint = stageProgress(motion.time, 0.32, 0.62);

  final presence = motion.presence;

  // The door paints on layers of its own: once it rests, the assets sway
  // over it without painting it again.
  return [
    Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _BackPainter(
              look: look,
              door: door.rect,
              trace: trace,
              build: build,
              lit: lit,
              flood: flood,
              edge: door.footOfEdge(angle),
              dots: 0.6 * stageProgress(e, 0.5, 1),
            ),
          ),
        ),
      ),
    ),
    Positioned.fromRect(
      rect: door.rect,
      child: RepaintBoundary(
        child: Opacity(
          opacity: build,
          child: _Leaf(
            look: look,
            width: door.width,
            height: door.height,
            angle: angle,
            glint: glint,
            shade: motion.swing,
          ),
        ),
      ),
    ),
    if (presence > 0)
      _assets(
        look,
        door,
        stage,
        motion,
        opacity: presence * build,
        scale: lerpDouble(0.5, 1, presence)!,
      ),
    StagePaintLayer((canvas, size) {
      final effects = look.effects(canvas, door.width / 2);
      final flash = motion.flash;
      if (flash != null) effects.flash(door.center, flash);
      effects.shockwave(door.center, reach, motion.shockwave, 0.5);
      effects.sparkles(door.center, motion.sparkle);
    }),
  ];
}

/// The assets out of the doorway, after the beats of the first page of the
/// onboarding: the Mooze coin grows in the doorway, and the coin of each
/// asset, in the colors of the asset, spirals out of it to an orbit in
/// front of the door, wider than the door but within the [stage], and
/// they sway back and forth. Two rings of light trace the orbit.
///
/// As the door shuts, they go back in: [opacity] and [scale] around the
/// doorway.
Widget _assets(
  _Look look,
  _Door door,
  Size stage,
  DoorMotion motion, {
  required double opacity,
  required double scale,
}) {
  final e = motion.arrival;
  final sway = motion.sway;
  final center = door.center;
  final coreSize = door.width * 0.56;
  final coinSize = door.width * 0.4;
  // The coins come forward of the door, out to its frame, as wide as the
  // stage lets them as they sway: at their widest, a coin is 0.9 of the
  // way along the orbit.
  final rx = math.max(
    0.0,
    math.min(door.width * 0.9, (stage.width / 2 - coinSize / 2 - 8) / 0.9),
  );
  final ry = rx * 0.55;
  const tilt = -0.08;
  final radius = coreSize / 2;
  final rings = [
    StageRing(
      width: rx / radius,
      height: ry / radius,
      tilt: tilt,
      turns: 0.6,
      phase: 1,
    ),
    StageRing(
      width: rx * 1.12 / radius,
      height: ry * 1.3 / radius,
      tilt: tilt + 0.12,
      turns: -0.45,
      phase: 3.4,
    ),
  ];
  // The coins spiral out of the Mooze coin to their orbit. They spread out
  // later than on the onboarding: they pass the sides of the orbit close
  // in, and reach it at its corners, so they stay on the screen.
  final spread = Curves.easeOutBack.transform(stageProgress(e, 0.35, 0.95));
  final spiral =
      math.pi * (1 - Curves.easeOutCubic.transform(stageProgress(e, 0.2, 1)));
  final turn = math.pi / 4 - spiral + 0.35 * sway;
  final ringAppear = Curves.easeOut.transform(stageProgress(e, 0.2, 0.7));
  final ringOrbit = 0.5 * e + 0.2 * sway;

  void paintRings(Canvas canvas, StageLayer layer) {
    final effects = look.effects(canvas, radius);
    for (final ring in rings) {
      effects.ring(
        center,
        ring,
        layer,
        appear: ringAppear,
        orbit: ringOrbit,
        scale: spread,
      );
    }
  }

  final coins = [
    for (final (k, asset) in Asset.values.indexed)
      (asset: asset, angle: turn + k * math.pi / 2, k: k),
  ]..sort((a, b) => math.sin(a.angle).compareTo(math.sin(b.angle)));
  Widget coin(({Asset asset, double angle, int k}) c) => StagePlaced(
    at: center + stageOrbitPoint(c.angle, rx, ry, tilt) * spread,
    size: coinSize,
    scale: lerpDouble(0.8, 1, stageNearness(c.angle))!,
    opacity: stageProgress(e, 0.1 + 0.08 * c.k, 0.35 + 0.08 * c.k),
    child: _ColoredCoin(
      asset: c.asset,
      size: coinSize,
      yaw: -0.55 * math.cos(c.angle),
      shadow: look.shadow,
    ),
  );

  return Positioned.fill(
    child: Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        origin: center - stage.center(Offset.zero),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            StagePaintLayer(
              (canvas, size) => paintRings(canvas, StageLayer.back),
            ),
            for (final c in coins)
              if (math.sin(c.angle) < 0) coin(c),
            StagePlaced(
              at: center,
              size: coreSize,
              scale: lerpDouble(
                0.6,
                1,
                Curves.easeOutBack.transform(stageProgress(e, 0, 0.5)),
              )!,
              opacity: stageProgress(e, 0, 0.25),
              child: GlyphToken(
                glyphPath: FirstAccessSceneView._moozeGlyph,
                size: coreSize,
                yaw: 0.3 + 0.25 * sway,
                tint: look.brand,
                palette: look.palette,
                glyphScale: 0.5,
              ),
            ),
            StagePaintLayer(
              (canvas, size) => paintRings(canvas, StageLayer.front),
            ),
            for (final c in coins)
              if (math.sin(c.angle) >= 0) coin(c),
          ],
        ),
      ),
    ),
  );
}

/// The coin of [asset] in the colors of the asset: its metal in the color
/// of its icon, and its symbol and its glint white. A colored coin keeps
/// its colors in both themes.
class _ColoredCoin extends StatelessWidget {
  const _ColoredCoin({
    required this.asset,
    required this.size,
    required this.yaw,
    required this.shadow,
  });

  final Asset asset;
  final double size;
  final double yaw;

  /// The shade of the emboss and the bevel, blended into the color.
  final Color shadow;

  @override
  Widget build(BuildContext context) {
    final color = CoinGlyphColors.colorOf(asset);
    const light = Colors.white;
    return AssetCoin(
      asset: asset,
      size: size,
      yaw: yaw,
      tint: light,
      palette: StagePalette(
        isDark: true,
        page: color,
        base: color,
        shade: Color.lerp(color, shadow, 0.55)!,
        glint: light,
      ),
    );
  }
}

/// Paints what is behind the door, see [_paintBack]. It paints again only
/// when the door moves.
class _BackPainter extends CustomPainter {
  const _BackPainter({
    required this.look,
    required this.door,
    required this.trace,
    required this.build,
    required this.lit,
    required this.flood,
    required this.edge,
    required this.dots,
  });

  final _Look look;

  /// The doorway.
  final Rect door;
  final double trace;
  final double build;
  final double lit;
  final double flood;
  final double edge;
  final double dots;

  @override
  void paint(Canvas canvas, Size size) => _paintBack(
    canvas,
    size,
    look,
    _Door(door),
    trace: trace,
    build: build,
    lit: lit,
    flood: flood,
    edge: edge,
    dots: dots,
  );

  @override
  bool shouldRepaint(_BackPainter old) =>
      old.look != look ||
      old.door != door ||
      old.trace != trace ||
      old.build != build ||
      old.lit != lit ||
      old.flood != flood ||
      old.edge != edge ||
      old.dots != dots;
}

/// What is behind the door: the glow, the floor and its light, the
/// doorway, the frame, and the line of light that draws it.
void _paintBack(
  Canvas canvas,
  Size size,
  _Look look,
  _Door door, {
  required double trace,
  required double build,
  required double lit,
  required double flood,
  required double edge,
  required double dots,
}) {
  final rect = door.rect;
  final effects = look.effects(canvas, door.width / 2)
    ..glow(door.center, lit * lerpDouble(0.45, 1, flood)!)
    ..dots(size, dots);

  // The floor: a horizon through the foot of the door, with ripples of
  // light under it.
  final floor = rect.bottom;
  final span = door.width * 1.8;
  final horizon = Rect.fromLTRB(
    door.center.dx - span,
    floor - 0.5,
    door.center.dx + span,
    floor + 0.5,
  );
  canvas.drawRect(
    horizon,
    Paint()
      ..shader = LinearGradient(
        colors: [
          look.brand.withValues(alpha: 0),
          look.brand.withValues(alpha: 0.45 * build),
          look.brand.withValues(alpha: 0),
        ],
      ).createShader(horizon),
  );
  effects.floor(
    Offset(door.center.dx, floor - door.width / 2 * 1.45),
    0.5 * lit * lerpDouble(0.5, 1, flood)!,
  );

  // The light that spills through the opening, from a point inside the
  // doorway, out on the floor toward the viewer: a faint wedge from the
  // seam, a carpet once the door opens.
  if (lit > 0 && edge < rect.right) {
    final source = Offset(door.center.dx, rect.top + door.height * 0.3);
    final end = math.min(size.height, floor + door.height * 0.55);
    final stretch = (end - source.dy) / (floor - source.dy);
    Offset cast(Offset point) => source + (point - source) * stretch;
    final near = Offset(edge, floor);
    final far = Offset(rect.right, floor);
    final spill = Path()
      ..moveTo(near.dx, near.dy)
      ..lineTo(far.dx, far.dy)
      ..lineTo(cast(far).dx, end)
      ..lineTo(cast(near).dx, end)
      ..close();
    canvas.drawPath(
      spill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            look.brand.withValues(
              alpha: 0.5 * lit * lerpDouble(0.4, 1, flood)!,
            ),
            look.brand.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTRB(rect.left, floor, rect.right, end))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  // The doorway: dark, then lit from inside, a tunnel of light once open.
  // It fills in with the frame, after the line of light has drawn it.
  final doorway = door.doorway;
  canvas
    ..save()
    ..clipRRect(doorway)
    ..drawRect(
      rect,
      Paint()
        ..color = Color.alphaBlend(
          look.brand.withValues(alpha: 0.12),
          look.palette.page,
        ).withValues(alpha: build),
    );
  if (lit > 0) {
    final deep = Color.lerp(look.brand, look.shadow, 0.35)!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.2),
          radius: 0.95,
          colors: [
            look.palette.glint.withValues(alpha: lit),
            look.brand.withValues(alpha: lit),
            deep.withValues(alpha: lit),
          ],
          stops: const [0, 0.62, 1],
        ).createShader(rect),
    );
    final vanish = Offset(door.center.dx, rect.top + door.height * 0.42);
    for (final (i, depth) in const [0.74, 0.52, 0.34, 0.2].indexed) {
      final arch = _Door._arch(
        Rect.fromLTRB(
          vanish.dx + (rect.left - vanish.dx) * depth,
          vanish.dy + (rect.top - vanish.dy) * depth,
          vanish.dx + (rect.right - vanish.dx) * depth,
          vanish.dy + (rect.bottom - vanish.dy) * depth,
        ),
      );
      canvas.drawRRect(
        arch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = look.palette.glint.withValues(
            alpha: (0.5 - 0.1 * i) * flood * lit,
          ),
      );
    }
  }
  canvas.restore();

  // The frame, and the light of the doorway on its inner edge.
  if (build > 0) {
    canvas
      ..drawDRRect(
        door.outer,
        doorway,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              look.metal(0.3).withValues(alpha: build),
              look.metal(0.12).withValues(alpha: build),
              look.metal(0.06).withValues(alpha: build),
            ],
          ).createShader(door.outer.outerRect),
      )
      ..drawRRect(
        doorway,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = look.light.withValues(alpha: 0.6 * lit * flood),
      );
  }

  // The line of light that draws the frame, with a bright head.
  if (trace > 0) {
    final metric = door.outline.computeMetrics().first;
    final length = metric.length * trace;
    canvas.drawPath(
      metric.extractPath(0, length),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [look.light, look.brand.withValues(alpha: 0.7)],
        ).createShader(door.outer.outerRect),
    );
    final head = metric.getTangentForOffset(length)?.position;
    if (head != null && trace < 1) {
      final fade = math.sin(math.pi * trace);
      canvas
        ..drawCircle(
          head,
          6,
          Paint()
            ..color = look.brand.withValues(alpha: 0.8 * fade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        )
        ..drawCircle(
          head,
          2,
          Paint()..color = look.light.withValues(alpha: fade),
        );
    }
  }

  // The light that leaks under the door.
  if (lit > 0) {
    final leak = Rect.fromLTRB(
      rect.left + 4,
      floor - 1,
      rect.right - 4,
      floor + 1,
    );
    canvas.drawRect(
      leak,
      Paint()
        ..color = look.light.withValues(alpha: 0.55 * lit)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
  }
}

/// The door, hinged on the left of the doorway and turned in by [angle],
/// in perspective. Thin layers of its shape stacked behind its face form
/// its thickness. The doorway clips it, as the wall around it would.
class _Leaf extends StatelessWidget {
  const _Leaf({
    required this.look,
    required this.width,
    required this.height,
    required this.angle,
    required this.glint,
    required this.shade,
  });

  final _Look look;
  final double width;
  final double height;
  final double angle;

  /// A band of light that sweeps across the face, from 0 to 1.
  final double glint;

  /// How far the face has turned away from the light, from 0 to 1.
  final double shade;

  static const int _layers = 8;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(top: Radius.circular(width / 2));
    final shape = RoundedRectangleBorder(borderRadius: radius);
    final depth = width * 0.06;
    final ridge = look.metal(0.22);
    final groove = look.metal(0.08);
    // The wordmark spans most of the arched panel.
    final wordmark = width * 0.5;
    return ClipRRect(
      borderRadius: radius,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, _Door.perspective)
          ..multiply(Matrix4.translationValues(-width / 2, 0, 0))
          ..rotateY(-angle)
          ..multiply(Matrix4.translationValues(width / 2, 0, 0)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // From the back to the face: no depth test, so the farthest
            // layer paints first.
            for (var i = _layers; i >= 1; i--)
              Transform(
                transform: Matrix4.translationValues(0, 0, depth * i / _layers),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: i.isEven ? ridge : groove,
                    shape: shape.copyWith(
                      side: BorderSide(
                        color: look.brand.withValues(
                          alpha: i == _layers ? 0.5 : 0.18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _DoorFacePainter(look),
                child: Align(
                  alignment: const Alignment(0, -0.3),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Embossed: its shadow, then the wordmark.
                      for (final (offset, color) in [
                        (const Offset(0.8, 1.2), look.palette.shade),
                        (Offset.zero, look.brand),
                      ])
                        Transform.translate(
                          offset: offset,
                          child: SvgPicture.asset(
                            FirstAccessSceneView._wordmark,
                            width: wordmark,
                            colorMapper: TwoToneGlyphColors(color),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            CustomPaint(
              painter: _DoorLightPainter(
                look: look,
                glint: glint,
                shade: shade,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The face of the door: a plate of the metal of the palette, lit from the
/// top left, with an arched panel above for the Mooze wordmark, a square
/// one below, a handle, and a rim in the brand pink.
class _DoorFacePainter extends CustomPainter {
  const _DoorFacePainter(this.look);

  final _Look look;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final face = _Door._arch(rect);
    canvas.drawRRect(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [look.metal(0.24), look.metal(0.1), look.palette.base],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );

    // The panels, sunk: a shade line under a fine line in the brand pink.
    final inset = size.width * 0.2;
    final corner = Radius.circular(size.width * 0.03);
    final upper = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height * 0.58,
    );
    final panels = [
      RRect.fromRectAndCorners(
        upper,
        topLeft: Radius.circular(upper.width / 2),
        topRight: Radius.circular(upper.width / 2),
        bottomLeft: corner,
        bottomRight: corner,
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          inset,
          size.height * 0.66,
          size.width - inset,
          size.height - inset,
        ),
        corner,
      ),
    ];
    for (final panel in panels) {
      canvas
        ..drawRRect(
          panel.shift(const Offset(0.8, 1.2)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = look.palette.shade,
        )
        ..drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = look.brand.withValues(alpha: 0.4),
        );
    }

    // The handle, between the panels, by the free edge.
    final handle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.9, size.height * 0.62),
        width: size.width * 0.05,
        height: size.height * 0.08,
      ),
      Radius.circular(size.width),
    );
    canvas.drawRRect(
      handle,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [look.light, look.brand],
        ).createShader(handle.outerRect),
    );

    canvas.drawRRect(
      face.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            look.light.withValues(alpha: 0.8),
            look.brand.withValues(alpha: 0.6),
            look.brand.withValues(alpha: 0.25),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_DoorFacePainter oldDelegate) => oldDelegate.look != look;
}

/// The light on the face of the door: a band that sweeps across it once,
/// and the shade as it turns away.
class _DoorLightPainter extends CustomPainter {
  const _DoorLightPainter({
    required this.look,
    required this.glint,
    required this.shade,
  });

  final _Look look;
  final double glint;
  final double shade;

  @override
  void paint(Canvas canvas, Size size) {
    if ((glint <= 0 || glint >= 1) && shade <= 0) return;
    final rect = Offset.zero & size;
    canvas
      ..save()
      ..clipRRect(_Door._arch(rect));
    if (glint > 0 && glint < 1) {
      final x = lerpDouble(-0.6, 1.6, Curves.easeInOutSine.transform(glint))!;
      final band = size.width * 0.4;
      final strength = math.sin(math.pi * glint);
      final light = look.palette.glint;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(x * size.width - band, 0),
            Offset(x * size.width + band, size.height * 0.4),
            [
              light.withValues(alpha: 0),
              light.withValues(alpha: 0.2 * strength),
              light.withValues(alpha: 0),
            ],
            const [0, 0.5, 1],
          ),
      );
    }
    if (shade > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = look.shadow.withValues(
            alpha: (look.palette.isDark ? 0.5 : 0.18) * shade,
          ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DoorLightPainter oldDelegate) =>
      oldDelegate.look != look ||
      oldDelegate.glint != glint ||
      oldDelegate.shade != shade;
}
