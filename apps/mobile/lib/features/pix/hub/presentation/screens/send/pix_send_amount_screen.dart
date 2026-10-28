import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_send_draft.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_amount_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_flow_expired_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_send_key_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_underline_field.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/cpf_cnpj_input_formatter.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Amount step of the send flow.
///
/// The amount is the hero of the step, with the balance below it. The
/// recipient follows, with the CPF or CNPJ of the key owner when the key is
/// not a document. Continue asks the backend for the withdrawal, which fixes
/// the provider fee that the review shows.
class PixSendAmountScreen extends ConsumerStatefulWidget {
  const PixSendAmountScreen({super.key});

  @override
  ConsumerState<PixSendAmountScreen> createState() =>
      _PixSendAmountScreenState();
}

class _PixSendAmountScreenState extends ConsumerState<PixSendAmountScreen> {
  final TextEditingController _taxIdController = TextEditingController();
  final FocusNode _taxIdFocus = FocusNode();
  late int _amountInCents;

  /// True after a continue tap. Errors that depend on finished input wait
  /// for it; errors about a too high amount show while the user types.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(pixSendControllerProvider).draft;
    _amountInCents = draft?.amountInCents ?? 0;
    final taxId = draft?.taxId;
    if (draft != null && draft.asksForTaxId && taxId != null) {
      _taxIdController.text = formatCpfCnpj(taxId);
    }
  }

  @override
  void dispose() {
    _taxIdController.dispose();
    _taxIdFocus.dispose();
    super.dispose();
  }

  String? _amountError(AppLocalizations t, int? balanceSats) {
    if (_amountInCents > PixSendDraft.maxAmountInCents) {
      return t.pix_hub_amount_error_max(
        formatBrlCents(PixSendDraft.maxAmountInCents),
      );
    }
    // The fee is still unknown here, so this check covers the payout only.
    // The quote step checks the full deposit.
    if (balanceSats != null &&
        _amountInCents * PixWithdrawal.depixUnitsPerCent > balanceSats) {
      return t.pix_hub_amount_error_balance;
    }
    if (!_submitted) return null;
    if (_amountInCents <= 0) return t.pix_hub_amount_error_empty;
    if (_amountInCents < PixSendDraft.minAmountInCents) {
      return t.pix_hub_amount_error_min(
        formatBrlCents(PixSendDraft.minAmountInCents),
      );
    }
    return null;
  }

  String? _taxIdError(AppLocalizations t, PixSendDraft draft) {
    if (!_submitted || !draft.asksForTaxId) return null;
    return switch (CpfValidator.validate(_taxIdController.text)) {
      null => null,
      CpfValidationError.empty => t.pix_hub_tax_id_error_empty,
      CpfValidationError.incomplete ||
      CpfValidationError.invalid => t.pix_hub_tax_id_error_invalid,
    };
  }

  /// From the amount, the keyboard action moves to the tax ID when the step
  /// asks for it, else it continues.
  void _onAmountSubmitted(PixSendDraft draft, int? balanceSats) {
    if (draft.asksForTaxId && !CpfValidator.isValid(_taxIdController.text)) {
      _taxIdFocus.requestFocus();
      return;
    }
    _continue(draft, balanceSats);
  }

  Future<void> _continue(PixSendDraft draft, int? balanceSats) async {
    final t = AppLocalizations.of(context);
    setState(() => _submitted = true);
    if (_amountError(t, balanceSats) != null || _taxIdError(t, draft) != null) {
      return;
    }

    final controller = ref.read(pixSendControllerProvider.notifier);
    if (draft.asksForTaxId) controller.setTaxId(_taxIdController.text);
    controller.setAmount(_amountInCents);
    FocusScope.of(context).unfocus();

    final ready = await controller.requestQuote();
    if (!mounted) return;
    if (ready) {
      context.push('/pix/send/review');
      return;
    }
    final failure = ref.read(pixSendControllerProvider).failure;
    if (failure != null) {
      AppSnackBar.error(context, pixHubFailureMessage(t, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(pixSendControllerProvider);
    final draft = state.draft;

    if (draft == null) {
      return PixFlowExpiredScaffold(title: t.pix_hub_send_title);
    }

    final balanceSats = ref.watch(pixDepixBalanceProvider).valueOrNull;
    final isBusy = state.isBusy;
    final taxIdValid =
        draft.asksForTaxId && CpfValidator.isValid(_taxIdController.text);

    return PixScreenScaffold(
      appBarTitle: t.pix_hub_send_title,
      title: t.pix_hub_amount_question,
      bottomAction: PrimaryButton(
        text: t.common_continue,
        isEnabled: _amountInCents > 0,
        isLoading: isBusy,
        onPressed: () => _continue(draft, balanceSats),
      ),
      children: [
        PixAmountField(
          initialAmountInCents: draft.amountInCents,
          readOnly: draft.amountIsFixed || isBusy,
          autofocus: !draft.amountIsFixed,
          errorText: _amountError(t, balanceSats),
          textInputAction: draft.asksForTaxId
              ? TextInputAction.next
              : TextInputAction.done,
          onSubmitted: () => _onAmountSubmitted(draft, balanceSats),
          onChanged: (cents) => setState(() => _amountInCents = cents),
        ),
        const SizedBox(height: 14),
        _BalanceLine(balanceSats: balanceSats),
        const SizedBox(height: 6),
        _Hint(
          icon: draft.amountIsFixed ? PixIcons.lock : PixIcons.info,
          text: draft.amountIsFixed
              ? t.pix_hub_amount_fixed_hint
              : t.pix_hub_amount_fee_hint,
        ),
        const SizedBox(height: 32),
        _Caption(t.pix_hub_summary_recipient),
        const SizedBox(height: 8),
        PixSendKeyCard(draft: draft),
        if (draft.asksForTaxId) ...[
          const SizedBox(height: 28),
          _Caption(t.pix_hub_tax_id_label),
          PixUnderlineField(
            controller: _taxIdController,
            focusNode: _taxIdFocus,
            // A fixed amount leaves the tax ID as the only input.
            autofocus: draft.amountIsFixed,
            readOnly: isBusy,
            hintText: t.pix_hub_tax_id_hint,
            errorText: _taxIdError(t, draft),
            keyboardType: TextInputType.number,
            inputFormatters: [CpfCnpjInputFormatter()],
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: _amountInCents > 0
                ? () => _continue(draft, balanceSats)
                : null,
            suffixIcon: taxIdValid
                ? Semantics(
                    label: t.pix_hub_tax_id_valid,
                    child: PixIcon(
                      PixIcons.success,
                      size: 20,
                      color: context.colors.positiveColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          _Hint(icon: PixIcons.shield, text: t.pix_hub_tax_id_help),
        ],
      ],
    );
  }
}

/// The DePix balance below the amount.
///
/// The line keeps its height while the balance loads, so the content below
/// does not move. The balance fades in when it arrives.
class _BalanceLine extends StatelessWidget {
  final int? balanceSats;

  const _BalanceLine({required this.balanceSats});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final balance = balanceSats;
    final color = context.colors.textSecondary;

    return AnimatedOpacity(
      opacity: balance == null ? 0 : 1,
      duration: Motion.of(context, Motion.durationBase),
      curve: Motion.curveMove,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: PixIcon(PixIcons.deposit, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              balance == null
                  ? ''
                  : t.pix_hub_amount_balance(formatDepixUnits(balance)),
              style: context.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small label above a block of the step.
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

/// Secondary note below an input, with an icon that names its kind.
class _Hint extends StatelessWidget {
  final PixIconData icon;
  final String text;

  const _Hint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    // Secondary, not tertiary: the tertiary gray fails 4.5:1 on the light
    // page background.
    final color = context.colors.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: PixIcon(icon, size: 15, color: color),
        ),
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
    );
  }
}
