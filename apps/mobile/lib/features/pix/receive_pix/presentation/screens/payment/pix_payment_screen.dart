import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/shared/utils/error_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail_row.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/in_card_action_button.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/analytics/events.dart';
import 'package:mooze_mobile/shared/analytics/providers.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/utils/formatters.dart';
import 'package:share_plus/share_plus.dart';

import 'providers/pix_deposit_provider.dart';
import 'widgets/payment_details_display.dart';
import 'widgets/qr_code_display.dart';
import 'widgets/timer_countdown_widget.dart';

class PixPaymentScreen extends ConsumerWidget {
  const PixPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final depositId =
        GoRouterState.of(context).pathParameters["transaction_id"] as String;
    final deposit = ref.watch(depositDataProvider(depositId));

    return deposit.when(
      data: (data) => data.fold(
        (err) => ErrorPixPaymentScreen(
          errorMessage: t.pix_payment_qr_error(humanizeError(context, err)),
        ),
        (deposit) => ValidPixPaymentScreen(deposit: deposit),
      ),
      error: (err, stackTrace) => ErrorPixPaymentScreen(
        errorMessage: t.pix_payment_qr_error(humanizeError(context, err)),
      ),
      loading: () => LoadingPixPaymentScreen(),
    );
  }
}

/// Leaves the payment screen. Without a screen below, it opens the Pix hub.
void _leavePayment(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/pix');
  }
}

/// The Pix charge: amount, time left, and the QR code, always in view for
/// the payer to scan. One panel follows, as in the details of a deposit:
/// what the deposit delivers, its fees, the copy and paste code with copy,
/// and the share of the code.
class ValidPixPaymentScreen extends StatefulWidget {
  final PixDeposit deposit;
  const ValidPixPaymentScreen({super.key, required this.deposit});

  @override
  State<ValidPixPaymentScreen> createState() => _ValidPixPaymentScreenState();
}

// When the charge was just created, the scene of the QR code covers this
// screen as it opens, and fades away to uncover it: see
// `PixQrLoadingOverlay`.
class _ValidPixPaymentScreenState extends State<ValidPixPaymentScreen> {
  void _showExpiredDialog() {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GlassAlertDialog(
        title: Text(t.human_verif_time_expired_title),
        content: Text(t.pix_payment_time_expired_body),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _leavePayment(context);
            },
            child: Text(t.common_ok),
          ),
        ],
      ),
    );
  }

  /// Shares the amount and the Pix code, for someone else to pay.
  Future<void> _share() async {
    final t = AppLocalizations.of(context);
    await SharePlus.instance.share(
      ShareParams(
        text: t.pix_deposit_share_message(
          formatBrlCents(widget.deposit.amountInCents),
          widget.deposit.pixKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final deposit = widget.deposit;
    return PixScreenScaffold(
      title: t.pix_payment_appbar_title,
      children: [
        _AmountHero(
          label: t.pix_deposit_value,
          amountInCents: deposit.amountInCents,
        ),
        const SizedBox(height: 12),
        TimerCountdown(
          expireAt: deposit.createdAt.add(const Duration(minutes: 20)),
          onExpired: _showExpiredDialog,
        ),
        const SizedBox(height: 28),
        PixQrCodeDisplay(
          pixQrData: deposit.pixKey,
          boxConstraints: const BoxConstraints(),
        ),
        const SizedBox(height: 28),
        PaymentDetailsDisplay(
          deposit: deposit,
          rows: [_CodeRow(code: deposit.pixKey)],
          links: [
            InCardActionButton(
              label: t.pix_deposit_share_action,
              subtitle: t.pix_deposit_share_action_subtitle,
              icon: Icons.ios_share_rounded,
              onPressed: _share,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            "Powered by depix.info",
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// The copy and paste code, short on screen and whole on copy.
///
/// A copy sends the `pix_code_copied` event, as the copy field before it.
class _CodeRow extends ConsumerWidget {
  const _CodeRow({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DetailRow(
      label: AppLocalizations.of(context).pix_hub_charge_code_label,
      value: truncateHashId(code),
      copyable: true,
      copyValue: code,
      onCopied: () => ref
          .read(analyticsProvider)
          .track(const AnalyticsEvent('pix_code_copied', {})),
    );
  }
}

/// The amount to pay: a muted currency symbol and large tabular digits.
class _AmountHero extends StatelessWidget {
  const _AmountHero({required this.label, required this.amountInCents});

  final String label;
  final int amountInCents;

  @override
  Widget build(BuildContext context) {
    const tabular = [FontFeature.tabularFigures()];
    // Reais always use the Brazilian format, whatever the app language.
    final digits = NumberFormat(
      '#,##0.00',
      'pt_BR',
    ).format(amountInCents / 100);
    final digitsStyle = context.textTheme.displaySmall?.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.8,
      height: 1.1,
      fontFeatures: tabular,
    );
    final symbolStyle = context.textTheme.titleLarge?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w500,
      fontFeatures: tabular,
    );

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          // A long amount or large text shrinks the line instead of
          // overflowing it.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(r'R$', style: symbolStyle),
                const SizedBox(width: 6),
                Text(digits, style: digitsStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the error that stopped the charge from loading.
class ErrorPixPaymentScreen extends StatelessWidget {
  final String errorMessage;
  const ErrorPixPaymentScreen({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _PaymentStateScaffold(
      bottomAction: PrimaryButton(
        text: t.common_back,
        onPressed: () => _leavePayment(context),
      ),
      child: PixStatusView(
        kind: PixStatusKind.failure,
        title: t.common_error,
        message: errorMessage,
      ),
    );
  }
}

/// Shows a spinner while the charge loads.
class LoadingPixPaymentScreen extends StatelessWidget {
  const LoadingPixPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PaymentStateScaffold(
      child: SizedBox.square(
        dimension: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: context.colors.textSecondary,
          // A still arc when animations are off.
          value: Motion.isReduced(context) ? 0.7 : null,
        ),
      ),
    );
  }
}

/// Page of the loading and error states: the backdrop, a clear app bar with
/// a back button, the content in the center, and an optional action.
class _PaymentStateScaffold extends StatelessWidget {
  const _PaymentStateScaffold({required this.child, this.bottomAction});

  final Widget child;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    const gutter = PixScreenScaffold.gutter;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _PaymentAppBar(onBack: () => _leavePayment(context)),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: gutter,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 48,
                        ),
                        child: Center(child: child),
                      ),
                    ),
                  ),
                ),
                if (bottomAction != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(gutter, 8, gutter, 12),
                    child: bottomAction!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A clear app bar with a back button that always leaves the screen.
///
/// It looks like `BackdropAppBar`. The back button opens the Pix hub when
/// no screen is below, so the loading and error states never trap the user.
class _PaymentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PaymentAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: BackButton(onPressed: onBack),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: context.colors.textPrimary,
      flexibleSpace: const AppBackdrop(),
    );
  }
}
