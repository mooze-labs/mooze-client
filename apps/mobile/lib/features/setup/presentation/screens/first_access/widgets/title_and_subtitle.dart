import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_screen_scaffold.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// The question of the first screen, centered, with the type of the other
/// setup screens.
class TitleAndSubtitle extends StatelessWidget {
  const TitleAndSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PinHeader(
      title: t.setup_first_access_title,
      subtitle: t.setup_first_access_subtitle,
      textAlign: TextAlign.center,
    );
  }
}
