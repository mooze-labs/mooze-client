import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/data/repositories/api_pix_payment_link_repository.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link_amount.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_receive_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_action_tile.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_amount_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_summary_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_picker_sheet.dart'
    show AssetLensLogo;
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Creates a payment link.
///
/// The amount bounds come from [PaymentLinkAmount], the `AmountPolicy` of the
/// payment-link API. The link pays a new address of the wallet, in the asset
/// that the user picks.
///
/// The amount is the hero of the step. The two switches share one glass
/// group, the assets another, and the reference is a bare underline field.
/// The review opens in a floating glass sheet, whose slide creates the link.
class PixPaymentLinkCreateScreen extends ConsumerStatefulWidget {
  const PixPaymentLinkCreateScreen({super.key});

  @override
  ConsumerState<PixPaymentLinkCreateScreen> createState() =>
      _PixPaymentLinkCreateScreenState();
}

class _PixPaymentLinkCreateScreenState
    extends ConsumerState<PixPaymentLinkCreateScreen> {
  final TextEditingController _referenceController = TextEditingController();

  int _amountInCents = 0;
  bool _openAmount = false;
  bool _singleUse = true;

  /// Asset that the wallet receives. DePix keeps the BRL value.
  Asset _asset = Asset.depix;

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  bool get _amountIsValid =>
      _openAmount || FixedPaymentLinkAmount(_amountInCents).isWithinBounds;

  /// The review opens once the link has an identification and an amount.
  bool get _canReview =>
      _referenceController.text.trim().isNotEmpty && _amountIsValid;

  /// The limits show once an amount is typed, so the disabled review has a
  /// visible reason.
  String? _amountError(AppLocalizations t) {
    if (_amountInCents == 0 || _amountIsValid) return null;
    return t.pix_hub_link_amount_error(
      formatBrlCents(PaymentLinkAmount.minAmountInCents),
      formatBrlCents(PaymentLinkAmount.maxAmountInCents),
    );
  }

  /// Shows the review sheet, whose slide creates the link.
  Future<void> _reviewAndCreate() async {
    final t = AppLocalizations.of(context);
    if (!_canReview) return;

    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      // The glass sheet draws its own floating surface.
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _ReviewSheet(
        reference: _referenceController.text.trim(),
        amountLabel: _openAmount
            ? t.pix_hub_link_open_amount
            : formatBrlCents(_amountInCents),
        usageLabel: _singleUse
            ? t.pix_hub_link_single_use
            : t.pix_hub_link_reusable,
        assetLabel: _asset.ticker,
        onCreate: () => _create(sheetContext),
      ),
    );
  }

  /// Creates the link while the slide of the review waits. The review then
  /// closes either way, so a failure shows on this screen, not behind the
  /// sheet.
  Future<void> _create(BuildContext sheetContext) async {
    final t = AppLocalizations.of(context);
    final link = await ref
        .read(pixPaymentLinkFormControllerProvider.notifier)
        .create(
          reference: _referenceController.text.trim(),
          singleUse: _singleUse,
          asset: _asset,
          amountInCents: _openAmount ? null : _amountInCents,
        );

    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    if (!mounted) return;
    if (link == null) {
      final failure = ref.read(pixPaymentLinkFormControllerProvider).failure;
      if (failure != null) {
        AppSnackBar.error(context, pixHubFailureMessage(t, failure));
      }
      return;
    }

    ref.invalidate(pixHubPaymentLinksProvider);
    context.pushReplacement('/pix/links/detail', extra: link);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isBusy = ref.watch(pixPaymentLinkFormControllerProvider).isBusy;

    return PixScreenScaffold(
      title: t.pix_hub_link_create,
      bottomAction: PrimaryButton(
        text: t.pix_hub_link_review,
        isEnabled: _canReview,
        isLoading: isBusy,
        onPressed: _reviewAndCreate,
      ),
      children: [
        _Caption(t.pix_hub_amount_label),
        const SizedBox(height: 10),
        // The field fades back while the payer chooses the amount, because
        // it no longer takes input.
        AnimatedOpacity(
          opacity: _openAmount ? 0.4 : 1,
          duration: Motion.of(context, Motion.durationFast),
          curve: Motion.curveMove,
          child: PixAmountField(
            autofocus: false,
            readOnly: _openAmount,
            errorText: _amountError(t),
            onChanged: (cents) => setState(() => _amountInCents = cents),
          ),
        ),
        const SizedBox(height: 24),
        PixSurfaceCard(
          child: Column(
            children: [
              _SwitchRow(
                icon: PixIcons.amount,
                title: t.pix_hub_charge_open_amount,
                value: _openAmount,
                onChanged: (value) => setState(() => _openAmount = value),
              ),
              Divider(
                height: 1,
                thickness: 1,
                // The divider starts at the row text.
                indent: PixActionTile.textInset,
                color: AppSurfaces.hairline(context),
              ),
              _SwitchRow(
                icon: PixIcons.lock,
                title: t.pix_hub_link_single_use,
                subtitle: t.pix_hub_link_single_use_hint,
                value: _singleUse,
                onChanged: (value) => setState(() => _singleUse = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _Caption(t.pix_hub_link_asset_title),
        const SizedBox(height: 10),
        PixSurfaceCard(
          child: Column(
            children: [
              for (final (index, asset)
                  in ApiPixPaymentLinkRepository.acceptedAssets.indexed) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: PixActionTile.textInset,
                    color: AppSurfaces.hairline(context),
                  ),
                _AssetRow(
                  asset: asset,
                  selected: asset == _asset,
                  onTap: () => setState(() => _asset = asset),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ReferenceField(
          controller: _referenceController,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

/// A row of the options group with a switch at the end.
///
/// A tap anywhere on the row flips the switch. [MergeSemantics] reads the
/// title, the hint, and the switch state as one control.
class _SwitchRow extends StatelessWidget {
  final PixIconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              PixIconWell(icon: icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// One asset that the link can pay, with a check when it is the chosen one.
///
/// The rows act as one choice: screen readers read the selection, and the
/// check carries it besides the color.
class _AssetRow extends StatelessWidget {
  final Asset asset;
  final bool selected;
  final VoidCallback onTap;

  const _AssetRow({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          child: Row(
            children: [
              AssetLensLogo(asset: asset, size: PixIconWell.defaultSize),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.ticker,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      asset.name,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: Motion.of(context, Motion.durationFast),
                child: PixIcon(
                  PixIcons.check,
                  size: 20,
                  color: context.colors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The reference of the link, drawn as a bare underline.
///
/// It follows the underline fields of the send flow. Unlike those, it keeps
/// sentence capitalization and suggestions, because it holds free text.
class _ReferenceField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _ReferenceField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    UnderlineInputBorder line(Color color, double width) =>
        UnderlineInputBorder(
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Caption(t.pix_hub_link_reference_label),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: t.pix_hub_link_reference_hint,
            hintStyle: context.textTheme.titleMedium?.copyWith(
              color: context.colors.textTertiary,
            ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            // The field sits on the page, where the light outline variant
            // has the page color. The outline shows in both themes.
            border: line(context.colorScheme.outline, 1),
            enabledBorder: line(context.colorScheme.outline, 1),
            focusedBorder: line(context.colors.primaryColor, 1.5),
          ),
        ),
      ],
    );
  }
}

/// Review step shown before the link is created.
///
/// The sheet is a floating glass surface, so the details sit on it directly,
/// split by hairlines, without a second panel.
class _ReviewSheet extends ConsumerWidget {
  final String reference;
  final String amountLabel;
  final String usageLabel;
  final String assetLabel;
  final VoidCallback onCreate;

  const _ReviewSheet({
    required this.reference,
    required this.amountLabel,
    required this.usageLabel,
    required this.assetLabel,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isBusy = ref.watch(
      pixPaymentLinkFormControllerProvider.select((state) => state.isBusy),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: GlassSheet(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: _SheetHandle()),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  t.pix_hub_link_review,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _SheetSummary(
                entries: [
                  PixSummaryEntry(t.pix_hub_link_reference_label, reference),
                  PixSummaryEntry(
                    t.pix_hub_summary_amount,
                    amountLabel,
                    highlight: true,
                  ),
                  PixSummaryEntry(t.pix_hub_link_asset_label, assetLabel),
                  PixSummaryEntry(t.pix_hub_link_usage_label, usageLabel),
                ],
              ),
              const SizedBox(height: 20),
              SlideToConfirmButton(
                text: t.pix_hub_link_confirm,
                isLoading: isBusy,
                onSlideComplete: onCreate,
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: isBusy ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.textPrimary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  t.common_cancel,
                  style: context.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The lines of the review, without a panel.
///
/// Each line is a label on the left and its value on the right, as in
/// [PixSummaryCard]. Values use tabular figures. The highlighted value, the
/// amount, is larger and bolder.
class _SheetSummary extends StatelessWidget {
  final List<PixSummaryEntry> entries;

  const _SheetSummary({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, entry) in entries.indexed) ...[
          if (index > 0)
            Divider(
              height: 1,
              thickness: 1,
              color: AppSurfaces.hairline(context),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: MergeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: entry.highlight
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      entry.label,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    flex: 2,
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.end,
                      style:
                          (entry.highlight
                                  ? context.textTheme.titleMedium
                                  : context.textTheme.bodyMedium)
                              ?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: entry.highlight
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Caption above an input, as in the send flow.
class _Caption extends StatelessWidget {
  final String text;

  const _Caption(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.labelLarge?.copyWith(
        color: context.colors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Short bar at the top of a sheet that shows it can be dragged down.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: context.colorScheme.onSurface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
