import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/seed_display.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:no_screenshot/no_screenshot.dart';

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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        await NoScreenshot.instance.screenshotOn();
      },
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
              Expanded(child: MnemonicGridDisplay(mnemonic: widget.mnemonic)),
              const SizedBox(height: 16),
              PrimaryButton(
                text: _copied ? t.seed_copied : t.seed_copy,
                isEnabled: !_copied,
                onPressed: _copied ? null : _copySeed,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _redirectToConfigureSeeds(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.push("/setup/create-wallet/configure-seeds");
    });
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
