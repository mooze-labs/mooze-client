import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_page_scaffold.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/seed_display.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/seed_reveal.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_segmented_control.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

enum _SeedView { words, qr }

class ViewMnemonicScreen extends ConsumerStatefulWidget {
  const ViewMnemonicScreen({super.key, required this.mnemonic});

  final String mnemonic;

  @override
  ConsumerState<ViewMnemonicScreen> createState() => _ViewMnemonicScreenState();
}

class _ViewMnemonicScreenState extends ConsumerState<ViewMnemonicScreen> {
  static const double _viewSwitchWidth = 280;

  /// Side of the QR code, without its margin.
  static const double _qrSize = 232;

  final _reveal = SeedRevealController();
  _SeedView _view = _SeedView.words;
  bool _copied = false;

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

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

    final showsQr = _view == _SeedView.qr;

    // Screenshot protection for this screen is handled by the `SecureScreen`
    // wrapper applied at the route level (see settings/routes.dart) — bound to
    // the widget lifecycle, not to a back-only `PopScope`.
    return SettingsPageScaffold(
      title: t.seed_screen_title,
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _viewSwitchWidth),
            child: GlassSegmentedControl<_SeedView>(
              expand: true,
              selected: _view,
              onChanged: (view) => setState(() => _view = view),
              segments: [
                GlassSegment(value: _SeedView.words, label: t.seed_view_words),
                GlassSegment(value: _SeedView.qr, label: t.seed_view_qr),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: _copied ? t.seed_copied : t.seed_copy,
            isEnabled: !_copied,
            onPressed: _copied ? null : _copySeed,
          ),
        ],
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
            SizeFadeSwitcher(
              child: TitleAndSubtitleCreateWallet(
                key: ValueKey(_view),
                title: showsQr ? t.seed_qr_title_prefix : t.seed_words_of,
                highlighted: showsQr
                    ? t.seed_qr_title_highlight
                    : t.seed_recovery_word,
                subtitle: showsQr ? t.seed_qr_subtitle : t.seed_save_warning,
              ),
            ),
            const SizedBox(height: 20),
            // The words and the QR code share one reveal. The words fit
            // their panel, and the code sits in the middle of the free space.
            Flexible(
              fit: showsQr ? FlexFit.tight : FlexFit.loose,
              child: showsQr
                  ? _buildQr(t)
                  : GlassPanel(
                      padding: const EdgeInsets.all(12),
                      child: SeedReveal(
                        controller: _reveal,
                        placeholder: MnemonicGridDisplay.masked(
                          widget.mnemonic,
                        ),
                        child: MnemonicGridDisplay(mnemonic: widget.mnemonic),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQr(AppLocalizations t) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SeedReveal(
                controller: _reveal,
                blurPlaceholder: false,
                placeholder: const _QrPlaceholder(size: _qrSize),
                child: PixQrPanel(
                  data: widget.mnemonic,
                  size: _qrSize,
                  semanticLabel: t.seed_qr_label,
                ),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _qrSize + 2 * PixQrPanel.margin,
                ),
                child: _QrWarning(text: t.seed_qr_warning),
              ),
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

  Widget _buildLoadingScaffold(AppLocalizations t) {
    return SettingsPageScaffold(
      title: t.seed_screen_title,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// The QR code while it is hidden: a glass tile of the same size, with a
/// faint code of similar density that holds no secret.
class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder({required this.size});

  final double size;

  static final _data = 'mooze ' * 12;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: size + 2 * PixQrPanel.margin,
        child: LiquidGlass(
          blurBackdrop: false,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(PixQrPanel.margin),
            child: SeedBlur(
              child: PrettyQrView.data(
                data: _data,
                decoration: PrettyQrDecoration(
                  shape: PrettyQrSmoothSymbol(
                    color: context.colors.textPrimary.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The risk of the code, in one quiet line below it.
class _QrWarning extends StatelessWidget {
  const _QrWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 18,
          color: context.appColors.warning,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
