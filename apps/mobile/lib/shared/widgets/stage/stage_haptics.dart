import 'package:flutter/widgets.dart';

/// A haptic that marks a moment of a stage: [play] runs when the animation
/// of the stage passes [at] while it runs forward.
typedef StageBeat = ({double at, Future<void> Function() play});

/// Plays the [stageBeats] of a stage, each once, while [stageAnimation]
/// runs forward. A stage that starts past 0, at rest or midway, plays none.
///
/// The system haptic setting applies to every beat.
mixin StageHaptics<T extends StatefulWidget> on State<T> {
  Animation<double> get stageAnimation;

  /// The beats in the order of their [StageBeat.at].
  List<StageBeat> get stageBeats;

  late Animation<double> _listened;

  /// Beats already played.
  late int _played;

  @override
  void initState() {
    super.initState();
    _listened = stageAnimation..addListener(_onTick);
    // Read now, not on the first tick: by then the scene has moved.
    _played = _listened.value > 0 ? stageBeats.length : 0;
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (stageAnimation == _listened) return;
    _listened.removeListener(_onTick);
    _listened = stageAnimation..addListener(_onTick);
  }

  @override
  void dispose() {
    _listened.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (_listened.status != AnimationStatus.forward) return;
    final t = _listened.value;
    final beats = stageBeats;
    while (_played < beats.length && t > 0 && t >= beats[_played].at) {
      beats[_played++].play();
    }
  }
}
