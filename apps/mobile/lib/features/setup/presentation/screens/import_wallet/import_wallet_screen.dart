import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/backdrop_page_scaffold.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'widgets.dart';
import 'providers/seed_phrase_provider.dart';

/// Imports a wallet from its recovery phrase, word by word or pasted.
///
/// The page sits on the screen backdrop: the guide and the typed words in
/// glass panels, a glass input, and the BIP39 suggestions above the
/// keyboard.
class ImportWalletScreen extends ConsumerStatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  ConsumerState<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends ConsumerState<ImportWalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(seedPhraseProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(seedPhraseProvider);
    // The page reaches the bottom edge, so the scroll keeps clear of the
    // home indicator by itself.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BackdropPageScaffold(
      title: t.setup_import_appbar,
      leading: BackButton(
        onPressed: () {
          ref.read(seedPhraseProvider.notifier).reset();
          context.pop();
        },
      ),
      actions: [
        if (state.confirmedWords.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            // The text color: the brand color stays on the import action.
            color: context.colors.textPrimary,
            tooltip: t.setup_import_restart_tooltip,
            onPressed: () {
              ref.read(seedPhraseProvider.notifier).reset();
            },
          ),
      ],
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                BackdropPageScaffold.gutter,
                8,
                BackdropPageScaffold.gutter,
                24 + bottomInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _ImportGuide(),
                  const SizedBox(height: 16),
                  const ClipboardPasteDetector(),
                  if (state.wordCount > 0) ...[
                    const SeedPhraseProgressIndicator(),
                    const SizedBox(height: 16),
                  ],
                  const ConfirmedWordsDisplay(),
                  if (state.confirmedWords.isNotEmpty)
                    const SizedBox(height: 16),
                  const MnemonicInputField(),
                  SizeFadeSwitcher(
                    child: state.canComplete
                        ? Padding(
                            key: ValueKey(state.isValid),
                            padding: const EdgeInsets.only(top: 12),
                            child: ImportStatusNote(
                              tone: state.isValid
                                  ? ImportStatusTone.positive
                                  : ImportStatusTone.warning,
                              text: state.isValid
                                  ? t.setup_import_seed_valid
                                  : t.setup_import_checksum_invalid,
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('no-status'),
                            width: double.infinity,
                          ),
                  ),
                  const SizedBox(height: 20),
                  const ImportButton(),
                  if (state.wordCount == 0) ...[
                    const SizedBox(height: 4),
                    const _ScanSeedQr(),
                    const SizedBox(height: 12),
                    _Tip(text: t.setup_import_tip),
                  ],
                ],
              ),
            ),
          ),
          const Bip39SuggestionsBar(),
        ],
      ),
    );
  }
}

/// How to type the phrase, in a glass panel at the top of the page, with
/// the vault of the onboarding: the phrase is the key to the wallet.
class _ImportGuide extends StatelessWidget {
  const _ImportGuide();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: MergeSemantics(
        child: Row(
          children: [
            ExcludeSemantics(
              child: GlyphToken(
                glyphPath: 'assets/images/onboarding/vault_lock.svg',
                size: 56,
                yaw: -0.3,
                tint: context.colors.primaryColor,
                palette: StagePalette.of(context),
                shape: const StarBorder.polygon(sides: 6, pointRounding: 0.24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.setup_import_instruction_title,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.setup_import_instruction_body,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the camera to read the phrase from a QR code.
class _ScanSeedQr extends StatelessWidget {
  const _ScanSeedQr();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.push('/setup/import-wallet/seed-qr'),
      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
      label: Text(AppLocalizations.of(context).setup_import_scan_seedqr),
      style: TextButton.styleFrom(
        foregroundColor: context.colors.textPrimary,
        minimumSize: const Size(double.infinity, 48),
        textStyle: context.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A quiet hint below the main action, with a bulb icon.
class _Tip extends StatelessWidget {
  final String text;

  const _Tip({required this.text});

  @override
  Widget build(BuildContext context) {
    // Secondary, not tertiary: the tertiary gray fails 4.5:1 on the light
    // page background.
    final color = context.colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
