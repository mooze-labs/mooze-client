import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/generate_seeds_button.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/phrase_length_selection.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_screen_scaffold.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// First step of a new wallet: the length of the recovery phrase.
///
/// It uses the page of the PIN screens: the backdrop, the title with the
/// highlighted word, and the main action at the bottom.
class ConfigureSeedsScreen extends StatelessWidget {
  const ConfigureSeedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PinScreenScaffold(
      appBarTitle: t.setup_create_wallet_appbar,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitleAndSubtitleCreateWallet(
            title: t.setup_seed_length_title,
            highlighted: t.setup_seed_length_highlight,
            subtitle: t.setup_seed_length_subtitle,
          ),
          const SizedBox(height: 24),
          const SeedPhraseSelector(),
          const Spacer(),
          const SizedBox(height: 24),
          const GenerateSeedsButton(),
        ],
      ),
    );
  }
}
