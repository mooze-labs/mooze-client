import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../widgets/receive_celebration.dart';
import '../widgets/send_funds/send_flow_parts.dart';

class TransactionConfirmedScreen extends StatefulWidget {
  final Asset asset;
  final BigInt amount;
  final String transactionId;

  const TransactionConfirmedScreen({
    super.key,
    required this.asset,
    required this.amount,
    required this.transactionId,
  });

  static void show(
    BuildContext context, {
    required Asset asset,
    required BigInt amount,
    required String transactionId,
  }) {
    final duration = Motion.of(context, Motion.durationBase);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => TransactionConfirmedScreen(
          asset: asset,
          amount: amount,
          transactionId: transactionId,
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
  State<TransactionConfirmedScreen> createState() =>
      _TransactionConfirmedScreenState();
}

class _TransactionConfirmedScreenState extends State<TransactionConfirmedScreen>
    with SingleTickerProviderStateMixin {
  /// Transactions whose entrance played in this session. Shown again, the
  /// screen opens at rest.
  static final Set<String> _celebrated = {};

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationReceive,
  );

  /// The title and the amount, once the scene rests.
  late final Animation<double> _reveal = _interval(0.7, 0.95);

  /// The transaction ID and the button, last.
  late final Animation<double> _details = _interval(0.8, 1);

  bool _started = false;

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
    parent: _controller,
    curve: Interval(begin, end, curve: Motion.curveEnter),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final firstShow =
        widget.transactionId.isEmpty || _celebrated.add(widget.transactionId);
    if (!firstShow || Motion.isReduced(context)) {
      _controller.value = 1;
      if (firstShow) HapticFeedback.lightImpact();
      return;
    }
    // The entrance starts once the route is in place.
    final route = ModalRoute.of(context)?.animation;
    if (route == null || route.isCompleted) {
      _controller.forward();
      return;
    }
    void start(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      route.removeStatusListener(start);
      if (mounted) _controller.forward();
    }

    route.addStatusListener(start);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns the received amount as its digits and its unit: sats for the
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (digits, unit) = _formatAmount(context);
    final transactionId = widget.transactionId;
    // The entrance plays on the page of its stage: black in the dark theme,
    // pearl in the light one.
    final palette = StagePalette.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
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
                        ReceiveCelebration(
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
                              title: t.tx_confirmed_title,
                              message: t.tx_received_asset(widget.asset.ticker),
                              child: _ReceivedAmount(
                                digits: digits,
                                unit: unit,
                              ),
                            ),
                          ),
                        ),
                        if (transactionId.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          FadeTransition(
                            opacity: _details,
                            child: PixCopyField(
                              label: t.tx_id,
                              value: transactionId,
                              icon: PixIcons.receipt,
                            ),
                          ),
                        ],
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
                    text: t.tx_back_to_dashboard,
                    onPressed: () => Navigator.of(context).pop(),
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

/// The "Received" caption and the received amount, centered under the
/// title.
class _ReceivedAmount extends StatelessWidget {
  const _ReceivedAmount({required this.digits, required this.unit});

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
            PixIcon(PixIcons.receive, size: 16, color: muted),
            const SizedBox(width: 6),
            Text(
              t.tx_received,
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
