import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_face.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_turn.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/utils/formatters.dart';

/// The end of a swap, on the stage of the celebrations: black in the dark
/// theme, pearl in the light one.
///
/// The coin of [fromAsset] spins up and turns into the coin of [toAsset],
/// with a flash, a shockwave, and two orbiting rings, see [StageTurn].
/// Once it lands, the title shows, then a glass panel with what was sent,
/// what is received, and the transaction ID, which a tap copies. Under
/// reduced motion everything shows at once, with one light haptic.
class SwapSuccessScreen extends StatefulWidget {
  final core.Asset fromAsset;
  final core.Asset toAsset;

  /// The amounts in whole units of their assets.
  final double amountSent;
  final double amountReceived;
  final String txid;

  const SwapSuccessScreen({
    super.key,
    required this.fromAsset,
    required this.toAsset,
    required this.amountSent,
    required this.amountReceived,
    required this.txid,
  });

  /// Width of the coin.
  static const double coinSize = 132;

  static void show(
    BuildContext context, {
    required core.Asset fromAsset,
    required core.Asset toAsset,
    required double amountSent,
    required double amountReceived,
    required String txid,
  }) {
    final duration = Motion.of(context, Motion.durationBase);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => SwapSuccessScreen(
          fromAsset: fromAsset,
          toAsset: toAsset,
          amountSent: amountSent,
          amountReceived: amountReceived,
          txid: txid,
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
  State<SwapSuccessScreen> createState() => _SwapSuccessScreenState();
}

class _SwapSuccessScreenState extends State<SwapSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationSwap,
  );

  /// The title, once the coin lands.
  late final Animation<double> _reveal = _interval(0.7, 0.92);

  /// The summary and the button, last.
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
    if (Motion.isReduced(context)) {
      _controller.value = 1;
      HapticFeedback.lightImpact();
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final palette = StagePalette.of(context);
    final brand = context.colors.primaryColor;
    const coinSize = SwapSuccessScreen.coinSize;

    Widget coin(core.Asset asset) =>
        StageFace.asset(asset, size: coinSize, tint: brand, palette: palette);

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
                        StageTurn(
                          animation: _controller,
                          size: coinSize,
                          height: 300,
                          from: coin(widget.fromAsset),
                          to: coin(widget.toAsset),
                          fromTint: brand,
                          toTint: brand,
                        ),
                        FadeTransition(
                          opacity: _reveal,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.9,
                              end: 1,
                            ).animate(_reveal),
                            child: _Headline(
                              title: t.swap_success_title,
                              message: t.swap_success_body,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _details,
                          child: _Summary(
                            fromAsset: widget.fromAsset,
                            toAsset: widget.toAsset,
                            amountSent: widget.amountSent,
                            amountReceived: widget.amountReceived,
                            txid: widget.txid,
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

/// The title and the message under the coin.
class _Headline extends StatelessWidget {
  const _Headline({required this.title, required this.message});

  final String title;
  final String message;

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
      ],
    );
  }
}

/// What was sent and what is received, one row each with the icon of the
/// asset, and the transaction ID, in one glass panel.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.fromAsset,
    required this.toAsset,
    required this.amountSent,
    required this.amountReceived,
    required this.txid,
  });

  final core.Asset fromAsset;
  final core.Asset toAsset;
  final double amountSent;
  final double amountReceived;
  final String txid;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AmountRow(
            label: t.swap_you_send,
            asset: fromAsset,
            amount: amountSent,
            sign: '−',
            emphasis: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 20,
                  color: context.colors.primaryColor,
                ),
                const SizedBox(width: 12),
                const Expanded(child: PanelDivider()),
              ],
            ),
          ),
          _AmountRow(
            label: t.swap_you_receive,
            asset: toAsset,
            amount: amountReceived,
            sign: '+',
            emphasis: true,
          ),
          const SizedBox(height: 16),
          _TxidLens(txid: txid),
        ],
      ),
    );
  }
}

/// One side of the swap: the icon of [asset], [label], and [amount] with
/// its [sign] and its unit. The received side is in [emphasis].
class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.asset,
    required this.amount,
    required this.sign,
    required this.emphasis,
  });

  final String label;
  final core.Asset asset;
  final double amount;
  final String sign;
  final bool emphasis;

  /// The amount as its digits and its unit: sats for the BTC-like assets,
  /// else the unit of the asset.
  (String, String) _format(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final digits = asset.formatAmount(
      (amount * 100000000).round(),
      locale: locale,
    );
    final unit = asset == core.Asset.btc || asset == core.Asset.lbtc
        ? 'sats'
        : asset.displayUnit;
    return (digits, unit);
  }

  @override
  Widget build(BuildContext context) {
    final (digits, unit) = _format(context);
    final muted = context.colors.textSecondary;
    final ink = emphasis ? context.colors.textPrimary : muted;
    return MergeSemantics(
      child: Row(
        children: [
          SvgPicture.asset(
            asset.iconPath,
            width: 36,
            height: 36,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$sign$digits'),
                      TextSpan(
                        text: ' $unit',
                        style: TextStyle(color: muted),
                      ),
                    ],
                  ),
                  style:
                      (emphasis
                              ? context.textTheme.titleLarge
                              : context.textTheme.titleMedium)
                          ?.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The transaction ID in a lens inside the panel. A tap copies it, and the
/// copy icon turns into a check for two seconds.
class _TxidLens extends StatefulWidget {
  const _TxidLens({required this.txid});

  final String txid;

  @override
  State<_TxidLens> createState() => _TxidLensState();
}

class _TxidLensState extends State<_TxidLens> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.txid));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final brand = context.colors.primaryColor;
    return Semantics(
      button: true,
      label: t.tx_id,
      child: GestureDetector(
        onTap: _copy,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.durationBase),
          curve: Motion.curveMove,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _copied
                ? brand.withValues(alpha: 0.08)
                : GlassStyle.of(context).lensFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: brand.withValues(alpha: _copied ? 0.5 : 0.2),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.tx_id,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      truncateHashId(widget.txid, length: 10),
                      style: context.textTheme.labelLarge?.copyWith(
                        color: _copied ? brand : context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: Motion.of(context, Motion.durationFast),
                child: Icon(
                  _copied ? Icons.check_rounded : Icons.copy_rounded,
                  key: ValueKey(_copied),
                  color: brand.withValues(alpha: _copied ? 1 : 0.7),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
