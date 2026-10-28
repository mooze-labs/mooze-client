import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Tells the user that a Pix deposit arrived.
///
/// The screen shows the success state, the amount, and the IDs of the
/// deposit, which the user can copy. It slides up from the bottom over
/// [Motion.durationEmphasis], or appears at once with reduced motion.
class PixSuccessScreen extends StatefulWidget {
  final Asset asset;
  final int amountInCents;
  final double assetAmount;
  final String depositId;
  final String? blockchainTxid;
  final VoidCallback? onClosed;

  const PixSuccessScreen({
    super.key,
    required this.asset,
    required this.amountInCents,
    required this.assetAmount,
    required this.depositId,
    this.blockchainTxid,
    this.onClosed,
  });

  static void show(
    BuildContext context, {
    required Asset asset,
    required int amountInCents,
    required double assetAmount,
    required String depositId,
    String? blockchainTxid,
    VoidCallback? onClosed,
  }) {
    final duration = Motion.of(context, Motion.durationEmphasis);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => PixSuccessScreen(
          asset: asset,
          amountInCents: amountInCents,
          assetAmount: assetAmount,
          depositId: depositId,
          blockchainTxid: blockchainTxid,
          onClosed: onClosed,
        ),
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Motion.curveLargeMove,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<PixSuccessScreen> createState() => _PixSuccessScreenState();
}

class _PixSuccessScreenState extends State<PixSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final txid = widget.blockchainTxid;
    return _PixOutcomeScaffold(
      action: PrimaryButton(
        text: t.refund_success_back_dashboard,
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      children: [
        PixStatusView(
          kind: PixStatusKind.success,
          title: t.pix_received_title,
          message: t.pix_received_body,
          child: _OutcomeAmount(amountInCents: widget.amountInCents),
        ),
        const SizedBox(height: 32),
        PixCopyField(label: t.pix_deposit_id_label, value: widget.depositId),
        if (txid != null) ...[
          const SizedBox(height: 12),
          PixCopyField(label: t.tx_id, value: txid),
        ],
      ],
    );
  }
}

/// The amount of the deposit: a muted currency symbol and large digits.
class _OutcomeAmount extends StatelessWidget {
  const _OutcomeAmount({required this.amountInCents});

  final int amountInCents;

  @override
  Widget build(BuildContext context) {
    const tabular = [FontFeature.tabularFigures()];
    // Reais always use the Brazilian format, whatever the app language.
    final digits = NumberFormat(
      '#,##0.00',
      'pt_BR',
    ).format(amountInCents / 100);
    return MergeSemantics(
      // A long amount or large text shrinks the line instead of
      // overflowing it.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              r'R$',
              style: context.textTheme.titleLarge?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w500,
                fontFeatures: tabular,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              digits,
              style: context.textTheme.displaySmall?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.8,
                height: 1.1,
                fontFeatures: tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page of a deposit outcome: the backdrop, a clear app bar, the content in
/// the middle of the screen, and the action pinned to the bottom.
///
/// The content scrolls when it does not fit, for example with large text.
class _PixOutcomeScaffold extends StatelessWidget {
  const _PixOutcomeScaffold({required this.children, required this.action});

  final List<Widget> children;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    const gutter = PixScreenScaffold.gutter;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const BackdropAppBar(),
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
                        vertical: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 32,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(gutter, 8, gutter, 12),
                  child: action,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
