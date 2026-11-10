import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_page_scaffold.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/seed_display.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';

class ViewMnemonicScreen extends ConsumerStatefulWidget {
  const ViewMnemonicScreen({super.key, required this.mnemonic});

  final String mnemonic;

  @override
  ConsumerState<ViewMnemonicScreen> createState() => _ViewMnemonicScreenState();
}

class _ViewMnemonicScreenState extends ConsumerState<ViewMnemonicScreen> {
  bool _copied = false;

  void _copySeed() async {
    await Clipboard.setData(ClipboardData(text: widget.mnemonic));
    setState(() => _copied = true);

    // desativa por 3 segundos
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (widget.mnemonic.isEmpty) {
      _redirectToConfigureSeeds(context);
      return _buildLoadingScaffold(t);
    }

    // Screenshot protection for this screen is handled by the `SecureScreen`
    // wrapper applied at the route level (see settings/routes.dart) — bound to
    // the widget lifecycle, not to a back-only `PopScope`.
    return SettingsPageScaffold(
      title: t.seed_screen_title,
      bottomAction: PrimaryButton(
        text: _copied ? t.seed_copied : t.seed_copy,
        isEnabled: !_copied,
        onPressed: _copied ? null : _copySeed,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          SettingsPageScaffold.gutter,
          16,
          SettingsPageScaffold.gutter,
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
            // The words sit in one glass panel, like the other groups of
            // the settings screens. The panel fits the words, and scrolls
            // only when they do not fit.
            Flexible(
              child: GlassPanel(
                padding: const EdgeInsets.all(12),
                child: MnemonicGridDisplay(mnemonic: widget.mnemonic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _redirectToConfigureSeeds(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.push("/setup/create-wallet/configure-seeds");
    });
  }

  Widget _buildLoadingScaffold(AppLocalizations t) {
    return SettingsPageScaffold(
      title: t.seed_screen_title,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
