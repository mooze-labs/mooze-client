import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/backdrop_page_scaffold.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';

import 'widgets.dart';

/// Shows the new recovery phrase before its confirmation.
///
/// It has the layout of the phrase in the settings: the words in one glass
/// panel on the backdrop, blurred until tapped, and the next step pinned at
/// the bottom.
class DisplaySeedsScreen extends ConsumerStatefulWidget {
  const DisplaySeedsScreen({super.key, required this.mnemonic});

  final String mnemonic;

  @override
  ConsumerState<DisplaySeedsScreen> createState() => _DisplaySeedsScreenState();
}

class _DisplaySeedsScreenState extends ConsumerState<DisplaySeedsScreen> {
  final _reveal = SeedRevealController();

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (widget.mnemonic.isEmpty) {
      _redirectToConfigureSeeds(context);
      return BackdropPageScaffold(
        title: t.seed_screen_title,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BackdropPageScaffold(
      title: t.seed_screen_title,
      leading: BackButton(onPressed: () => context.pop()),
      bottomAction: PrimaryButton(
        text: t.seed_confirm_phrase,
        onPressed: () => _goToConfirmSeeds(context),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          BackdropPageScaffold.gutter,
          16,
          BackdropPageScaffold.gutter,
          8,
        ),
        child: Column(
          children: [
            TitleAndSubtitleCreateWallet(
              title: t.seed_words_of,
              highlighted: t.seed_recovery_word,
              subtitle: t.seed_save_warning,
            ),
            const SizedBox(height: 20),
            // The panel fits the words, and scrolls only when they do not fit.
            Flexible(
              child: GlassPanel(
                padding: const EdgeInsets.all(12),
                child: SeedReveal(
                  controller: _reveal,
                  placeholder: MnemonicGridDisplay.masked(widget.mnemonic),
                  child: MnemonicGridDisplay(mnemonic: widget.mnemonic),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _redirectToConfigureSeeds(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go("/setup/create-wallet/configure-seeds");
    });
  }

  void _goToConfirmSeeds(BuildContext context) {
    context.push("/setup/create-wallet/confirm-seeds", extra: widget.mnemonic);
  }
}
