import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_deposit_ownership_notice.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_own_payer_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/own_deposit_payer.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_deposit_profile_service_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Step the user walks through before their first Pix deposit.
///
/// It shows the payer document of the deposits and takes the
/// acknowledgement of the bank account ownership notice. The document is
/// the one of the favorite payer marked as "my user": the screen never
/// takes it from anywhere else. Without that payer, the card asks the user
/// to register and mark one, and the screen does not continue.
///
/// Mooze has no service that proves who owns the paying bank account, so
/// the screen never states that the document was verified.
class PixDepositGateScreen extends ConsumerStatefulWidget {
  const PixDepositGateScreen({super.key});

  @override
  ConsumerState<PixDepositGateScreen> createState() =>
      _PixDepositGateScreenState();
}

class _PixDepositGateScreenState extends ConsumerState<PixDepositGateScreen> {
  bool _acknowledged = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _acknowledged = ref
        .read(pixDepositProfileServiceProvider)
        .hasAcknowledgedOwnershipNotice();
  }

  Future<void> _continue() async {
    final own = await readOwnDepositPayer(ref);
    if (own == null || !_acknowledged || !mounted) return;

    setState(() => _isSaving = true);
    await ref
        .read(pixDepositProfileServiceProvider)
        .acknowledgeOwnershipNotice();

    if (!mounted) return;
    setState(() => _isSaving = false);
    context.pushReplacement('/pix/deposit');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final own = ref.watch(ownDepositPayerProvider);
    final hasPayer = !own.hasError && own.valueOrNull != null;

    return PixScreenScaffold(
      appBarTitle: t.pix_hub_shortcut_deposit,
      title: t.pix_hub_deposit_gate_title,
      subtitle: t.pix_hub_deposit_gate_subtitle,
      bottomAction: PrimaryButton(
        text: t.common_continue,
        isEnabled: hasPayer && _acknowledged,
        isLoading: _isSaving,
        onPressed: _continue,
      ),
      children: [
        const PixOwnPayerCard(),
        const SizedBox(height: 8),
        _Hint(t.pix_hub_deposit_cpf_hint),
        const SizedBox(height: 28),
        const PixDepositOwnershipNotice(),
        const SizedBox(height: 8),
        _AcknowledgeTile(
          label: t.pix_hub_deposit_notice_ack,
          value: _acknowledged,
          onChanged: (value) => setState(() => _acknowledged = value),
        ),
      ],
    );
  }
}

/// Reopens the ownership notice after the user acknowledged it.
///
/// It also shows the payer document of the deposits. The user changes it in
/// the favorite payers.
class PixDepositNoticeScreen extends ConsumerWidget {
  const PixDepositNoticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final own = ref.watch(ownDepositPayerProvider);
    final hasPayer = !own.hasError && own.valueOrNull != null;

    return PixScreenScaffold(
      title: t.pix_hub_deposit_notice_screen_title,
      // Without a payer, the card below carries the same action.
      bottomAction: hasPayer
          ? SecondaryButton(
              text: t.pix_hub_deposit_change_cpf,
              onPressed: () => context.push('/favorite-payers'),
            )
          : null,
      children: [
        const PixDepositOwnershipNotice(),
        const SizedBox(height: 24),
        const PixOwnPayerCard(),
        const SizedBox(height: 10),
        _Hint(t.pix_hub_deposit_cpf_hint),
      ],
    );
  }
}

/// Secondary note below an input.
class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colors.textTertiary,
        height: 1.4,
      ),
    );
  }
}

/// Checkbox row that confirms the ownership notice.
///
/// The whole row is the touch target. The checked box uses the brand
/// color, because it marks a selection.
class _AcknowledgeTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AcknowledgeTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      controlAffinity: ListTileControlAffinity.leading,
      // The theme draws the box. The outline keeps the empty box visible
      // on the light page.
      side: BorderSide(color: context.colorScheme.outline, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        label,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.textPrimary,
        ),
      ),
      onChanged: (checked) => onChanged(checked ?? false),
    );
  }
}
