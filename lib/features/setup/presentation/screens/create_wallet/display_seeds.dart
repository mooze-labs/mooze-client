import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/platform_safe_area.dart';

import 'widgets.dart';

class DisplaySeedsScreen extends ConsumerWidget {
  const DisplaySeedsScreen({super.key, required this.mnemonic});

  final String mnemonic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);

    if (mnemonic.isEmpty) {
      _redirectToConfigureSeeds(context);
      return _buildLoadingScaffold(t);
    }

    return PlatformSafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context, t),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              TitleAndSubtitleCreateWallet(
                title: t.seed_words_of,
                highlighted: t.seed_recovery_word,
                subtitle: t.seed_save_warning,
              ),
              const SizedBox(height: 24),
              Expanded(child: MnemonicGridDisplay(mnemonic: mnemonic)),
              const SizedBox(height: 16),
              PrimaryButton(
                text: t.seed_confirm_phrase,
                onPressed: () => _goToConfirmSeeds(context),
              ),
            ],
          ),
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
    context.push("/setup/create-wallet/confirm-seeds", extra: mnemonic);
  }

  AppBar _buildAppBar(BuildContext context, AppLocalizations t) {
    return AppBar(
      title: Text(t.seed_screen_title),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildLoadingScaffold(AppLocalizations t) {
    return Scaffold(
      appBar: AppBar(title: Text(t.seed_screen_title)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
