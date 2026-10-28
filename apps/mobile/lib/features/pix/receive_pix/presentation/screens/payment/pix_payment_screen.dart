import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/shared/utils/error_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'providers/pix_deposit_provider.dart';
import 'widgets/copyable_address.dart';
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

/// The Pix charge: amount, time left, QR code, copy and paste code, and
/// what the deposit delivers.
class ValidPixPaymentScreen extends StatefulWidget {
  final PixDeposit deposit;
  const ValidPixPaymentScreen({super.key, required this.deposit});

  @override
  State<ValidPixPaymentScreen> createState() => _ValidPixPaymentScreenState();
}

class _ValidPixPaymentScreenState extends State<ValidPixPaymentScreen>
    with TickerProviderStateMixin {
  // The screen opens under the full pink circle of the loading overlay of
  // the previous screen. This overlay shrinks and fades that circle, so the
  // two screens join without a cut.
  late AnimationController _reverseCircleController;
  late Animation<double> _reverseCircleAnimation;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _initializeReverseAnimation();
  }

  void _initializeReverseAnimation() {
    _reverseCircleController = AnimationController(
      duration: Motion.durationCelebrate,
      vsync: this,
    );
    _reverseCircleAnimation = Tween<double>(begin: 3.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _reverseCircleController,
        curve: Motion.curveExit,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // With reduced motion, the screen shows at once, without the circle.
      if (!mounted || Motion.isReduced(context)) return;
      _showReverseOverlay();
      _reverseCircleController.forward().then((_) {
        _hideReverseOverlay();
      });
    });
  }

  void _showReverseOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _reverseCircleController,
        builder: (context, child) {
          final size = MediaQuery.of(context).size;
          final progress = _reverseCircleAnimation.value / 3.0;

          return IgnorePointer(
            ignoring: true,
            child: Material(
              color: Colors.transparent,
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    // The circle that shrinks.
                    Positioned(
                      left: -size.width * 1.2,
                      bottom: -size.height * 0.3,
                      child: Container(
                        width: size.width * _reverseCircleAnimation.value * 1.2,
                        height:
                            size.width * _reverseCircleAnimation.value * 1.2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colors.primaryColor,
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: progress,
                      child: Container(color: context.colors.primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideReverseOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _reverseCircleController.dispose();
    super.dispose();
  }

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
        CopyableAddress(
          pixKey: deposit.pixKey,
          label: t.pix_hub_charge_code_label,
        ),
        const SizedBox(height: 16),
        PaymentDetailsDisplay(deposit: deposit),
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
