import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_scene.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_haptics.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// Drives a [BiometricScene] through a system prompt: the entrance of the
/// seal, its scan while the prompt is up, a shake when it fails, and its
/// [finale] when it succeeds.
///
/// The state of a screen owns it: it passes itself as the vsync, keeps
/// [still] in step with the system, plays [beats] with [StageHaptics] on
/// [success], shows it with [BiometricSealView], and disposes it.
class BiometricSeal {
  BiometricSeal({
    required TickerProvider vsync,
    required this.finale,
    bool entered = false,
  }) : _ambient = AnimationController(
         vsync: vsync,
         duration: Motion.durationAmbient * 2,
         value: entered ? 1 : 0,
       ),
       _scan = AnimationController(vsync: vsync, duration: Motion.durationBase),
       _sweep = AnimationController(
         vsync: vsync,
         duration: Motion.durationScan,
       ),
       _success = AnimationController(vsync: vsync, duration: finale.duration),
       _shake = AnimationController(
         vsync: vsync,
         duration: Motion.durationEmphasis,
       );

  /// How a success ends.
  final BiometricFinale finale;

  /// Whether the system asks for reduced motion: the seal then shows each
  /// state at once.
  bool still = false;

  /// The entrance of the seal, then its sway, until it rests.
  final AnimationController _ambient;
  final AnimationController _scan;
  final AnimationController _sweep;
  final AnimationController _success;
  final AnimationController _shake;

  late final Listenable listenable = Listenable.merge([
    _ambient,
    _scan,
    _sweep,
    _success,
    _shake,
  ]);

  /// The success, for the captions and the haptics of the screen.
  Animation<double> get success => _success;

  /// The haptics of the success: a medium one at the peak, and, when the
  /// seal turns into the coin, a light one at edge-on.
  List<StageBeat> get beats => [
    (at: finale.peakAt, play: HapticFeedback.mediumImpact),
    if (finale == BiometricFinale.coin)
      (at: BiometricScene.edgeOnAt, play: HapticFeedback.lightImpact),
  ];

  BiometricMotion get motion => BiometricMotion(
    ambient: _ambient.value,
    scan: _scan.value,
    sweep: _sweep.value,
    success: _success.value,
    shake: _shake.value,
  );

  /// The seal comes in, sways, and rests within 5 s.
  void enter() {
    if (still) {
      _ambient.value = 1;
    } else {
      _ambient.forward(from: 0);
    }
  }

  /// The system prompt is up: the seal scans.
  void scan() {
    if (still) {
      _scan.value = 1;
      // The beam rests across the middle of the seal.
      _sweep.value = 0.25;
    } else {
      _scan.forward();
      _sweep.repeat();
    }
  }

  /// The system prompt closed with nothing to tell: the scan fades.
  void stopScanning() {
    _sweep.stop();
    if (still) {
      _scan.value = 0;
    } else {
      _scan.reverse();
    }
  }

  /// The system prompt failed: the seal shakes, with a heavy haptic.
  void fail() {
    stopScanning();
    HapticFeedback.heavyImpact();
    if (!still) _shake.forward(from: 0);
  }

  /// The system prompt succeeded: the seal plays its [finale]. Completes
  /// when the screen goes on, at [BiometricFinale.handOffAt]. Under reduced
  /// motion, the seal shows its end at once, with a light haptic.
  Future<void> succeed() {
    stopScanning();
    // The picture rests as the success plays.
    _ambient.stop();
    if (still) {
      _success.value = 1;
      HapticFeedback.lightImpact();
      return Future.value();
    }
    final forward = _success.forward();
    if (finale.handOffAt >= 1) return forward;
    final handOff = Completer<void>();
    void listener() {
      if (_success.value < finale.handOffAt) return;
      _success.removeListener(listener);
      handOff.complete();
    }

    _success.addListener(listener);
    return handOff.future;
  }

  void dispose() {
    _ambient.dispose();
    _scan.dispose();
    _sweep.dispose();
    _success.dispose();
    _shake.dispose();
  }
}

/// The [BiometricScene] of [seal], with the [kind] of the device.
class BiometricSealView extends StatelessWidget {
  const BiometricSealView({super.key, required this.seal, required this.kind});

  final BiometricSeal seal;
  final BiometricKind kind;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: seal.listenable,
    builder: (context, _) =>
        BiometricScene(kind: kind, motion: seal.motion, finale: seal.finale),
  );
}
