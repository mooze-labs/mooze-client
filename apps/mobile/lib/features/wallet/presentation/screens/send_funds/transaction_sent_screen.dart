import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';

import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/address_controller_provider.dart';
import '../../providers/send_funds/amount_provider.dart';
import '../../providers/send_funds/amount_controller_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../widgets/send_celebration.dart';
import '../../widgets/send_funds/send_flow_parts.dart';

/// Success step of a send, on the stage of the celebrations: black in the
/// dark theme, pearl in the light one.
///
/// A paper plane takes the payment away from the coin of the sent asset,
/// see [SendCelebration]. Once the plane is away, the title and the sent
/// amount show, then copy fields with the destination and, when known, the
/// transaction ID, and one button that ends the send. Under reduced motion
/// everything shows at once, with one light haptic.
class TransactionSentScreen extends ConsumerStatefulWidget {
  final Asset asset;
  final BigInt amount;
  final String destinationAddress;

  /// ID of the broadcast transaction. The screen hides its copy field when
  /// it is null.
  final String? transactionId;

  /// Runs instead of the end of the send, which clears the send form and
  /// goes home, for example to close a preview.
  final VoidCallback? onDone;

  const TransactionSentScreen({
    super.key,
    required this.asset,
    required this.amount,
    required this.destinationAddress,
    this.transactionId,
    this.onDone,
  });

  static void show(
    BuildContext context, {
    required Asset asset,
    required BigInt amount,
    required String destinationAddress,
    String? transactionId,
    VoidCallback? onDone,
  }) {
    final duration = Motion.of(context, Motion.durationBase);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => TransactionSentScreen(
          asset: asset,
          amount: amount,
          destinationAddress: destinationAddress,
          transactionId: transactionId,
          onDone: onDone,
        ),
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Motion.curveEnter,
              reverseCurve: Motion.curveExit,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  ConsumerState<TransactionSentScreen> createState() =>
      _TransactionSentScreenState();
}

class _TransactionSentScreenState extends ConsumerState<TransactionSentScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationSend,
  );

  /// The title and the amount, once the plane is away.
  late final Animation<double> _reveal = _interval(0.7, 0.95);

  /// The copy fields and the button, last.
  late final Animation<double> _details = _interval(0.8, 1);

  bool _started = false;
  Timer? _refresh;

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
    parent: _controller,
    curve: Interval(begin, end, curve: Motion.curveEnter),
  );

  @override
  void initState() {
    super.initState();
    _refreshBalances();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.isReduced(context)) {
      _controller.value = 1;
      HapticFeedback.lightImpact();
      return;
    }
    final route = ModalRoute.of(context);
    // On the first frame of a push the route is built offstage, where its
    // animation reads as complete. The check waits for the next frame.
    if (route != null && route.offstage) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _startOnceInPlace(route),
      );
    } else {
      _startOnceInPlace(route);
    }
  }

  /// Starts the scene once [route] is in place, at once if it already is.
  void _startOnceInPlace(ModalRoute<Object?>? route) {
    if (!mounted) return;
    final entrance = route?.animation;
    if (entrance == null || entrance.isCompleted) {
      _controller.forward();
      return;
    }
    void start(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      entrance.removeStatusListener(start);
      if (mounted) _controller.forward();
    }

    entrance.addStatusListener(start);
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Updates balances after successful send.
  ///
  /// Phase 2.3.3: routes through V2 `RefreshWalletUseCase(strategy: light)`
  /// instead of legacy `walletDataManager.refreshWalletData`. The 1s
  /// pre-delay is preserved (gives the broadcast tx a head start to
  /// surface in the next sync's `listPayments` walk). Fire-and-forget —
  /// failure to refresh is not a send failure (the broadcast already
  /// succeeded); the orchestrator's tx stream + periodic ticker
  /// reconcile UI state on the next emission. Leaving the screen before
  /// the delay cancels it.
  void _refreshBalances() {
    _refresh = Timer(const Duration(seconds: 1), () async {
      try {
        final useCase = await ref.read(refreshWalletProvider.future);
        await useCase(strategy: SyncStrategy.light);
      } catch (_) {
        // Swallowed by design.
      }
    });
  }

  /// Returns the sent amount as its digits and its unit: sats for the
  /// BTC-like assets, else the unit of the asset.
  (String, String) _formatAmount(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final asset = widget.asset;
    final digits = asset.formatAmount(widget.amount.toInt(), locale: locale);
    final unit = asset == Asset.btc || asset == Asset.lbtc
        ? 'sats'
        : asset.displayUnit;
    return (digits, unit);
  }

  void _handleClose() {
    final onDone = widget.onDone;
    if (onDone != null) {
      onDone();
      return;
    }

    // Clear the TextEditingControllers
    ref.read(addressControllerProvider).clear();
    ref.read(amountControllerProvider).clear();

    // Clear the StateProviders
    ref.read(addressStateProvider.notifier).state = '';
    ref.read(amountStateProvider.notifier).state = 0;
    ref.read(formattedAmountProvider.notifier).state = '0';
    ref.read(selectedAssetProvider.notifier).state = Asset.lbtc;

    // Clear validation
    ref.read(sendValidationControllerProvider.notifier).clearValidation();

    // Navigate to home
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (digits, unit) = _formatAmount(context);
    final transactionId = widget.transactionId;
    // The scene plays on the page of its stage: black in the dark theme,
    // pearl in the light one.
    final palette = StagePalette.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _handleClose();
          }
        },
        child: Scaffold(
          backgroundColor: palette.page,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      // The shockwave crosses the whole screen.
                      clipBehavior: Clip.none,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SendCelebration(
                            asset: widget.asset,
                            animation: _controller,
                          ),
                          FadeTransition(
                            opacity: _reveal,
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.9,
                                end: 1,
                              ).animate(_reveal),
                              child: _Headline(
                                title: t.tx_sent_title,
                                message: t.tx_sent_subtitle(
                                  widget.asset.ticker,
                                ),
                                child: _SentAmount(digits: digits, unit: unit),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          FadeTransition(
                            opacity: _details,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PixCopyField(
                                  label: t.wallet_send_destination_address,
                                  value: widget.destinationAddress,
                                  icon: PixIcons.send,
                                ),
                                if (transactionId != null &&
                                    transactionId.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  PixCopyField(
                                    label: t.tx_id,
                                    value: transactionId,
                                    icon: PixIcons.receipt,
                                  ),
                                ],
                                const SizedBox(height: 20),
                                Text(
                                  t.tx_sent_track_history,
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.bodySmall?.copyWith(
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
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: FadeTransition(
                    opacity: _details,
                    child: PrimaryButton(
                      text: t.refund_success_back_dashboard,
                      onPressed: _handleClose,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The title, the message, and the amount under the coin.
class _Headline extends StatelessWidget {
  const _Headline({
    required this.title,
    required this.message,
    required this.child,
  });

  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

/// The "Sent" caption and the sent amount, centered under the title.
class _SentAmount extends StatelessWidget {
  const _SentAmount({required this.digits, required this.unit});

  final String digits;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final muted = context.colors.textSecondary;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixIcon(PixIcons.send, size: 16, color: muted),
            const SizedBox(width: 6),
            Text(
              t.tx_sent_status_label,
              style: context.textTheme.labelLarge?.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SendHeroAmount(digits: digits, unit: unit, alignment: Alignment.center),
      ],
    );
  }
}
