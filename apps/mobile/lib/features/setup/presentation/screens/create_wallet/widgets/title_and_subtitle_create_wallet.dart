import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_screen_scaffold.dart';

/// The title and the instruction of a recovery phrase screen.
///
/// The title ends with [highlighted] in the brand color. It has the type of
/// the PIN screens, so the whole setup flow reads as one.
class TitleAndSubtitleCreateWallet extends StatelessWidget {
  final String title;
  final String highlighted;
  final String subtitle;

  const TitleAndSubtitleCreateWallet({
    super.key,
    required this.title,
    required this.highlighted,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return PinHeader(title: title, highlight: highlighted, subtitle: subtitle);
  }
}
