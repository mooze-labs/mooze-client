import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/data_refresh_trigger.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_display_mode_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_total_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/percentage_variation_display.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/user/providers/values_to_receive_provider.dart';
import 'package:mooze_mobile/shared/widgets/motion/animated_amount.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Mask that replaces the digits of a hidden amount.
///
/// The mask has a fixed length, so it does not show the size of the balance.
const String balanceMask = '••••••';

/// A total balance split into the parts that the hero styles differently.
@immutable
class BalanceAmount {
  const BalanceAmount({
    this.prefix = '',
    required this.digits,
    this.suffix = '',
    required this.value,
    this.format,
  });

  /// Currency symbol before the digits, for example "R$".
  final String prefix;

  /// The formatted number.
  final String digits;

  /// Unit after the digits, for example "BTC" or "sats".
  final String suffix;

  /// The numeric value. It sets the direction of a value change.
  final double value;

  /// Formats any value in the unit of [digits]. The count-up after a tap
  /// uses it for the values between 0 and [value]. Null disables the
  /// count-up.
  final String Function(double value)? format;

  String get fullText =>
      [prefix, digits, suffix].where((part) => part.isNotEmpty).join(' ');
}

/// The wallet balance hero of the home and the holdings screens. It reads
/// the wallet providers and shows [BalanceHeroView].
///
/// A tap on the amount cycles fiat, BTC, and sats. The eye button toggles
/// [isVisibleProvider].
class BalanceHero extends ConsumerWidget {
  const BalanceHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `isVisibleProvider` is true when the balance is hidden.
    final isHidden = ref.watch(isVisibleProvider);
    final displayMode = ref.watch(walletDisplayModeProvider);

    // Watch the refresh trigger to re-render without loading state.
    ref.watch(dataRefreshTriggerProvider);

    final currencyIcon = ref.watch(currencyControllerProvider.notifier).icon;
    final numberFormat = NumberFormat(
      '#,##0.00',
      Localizations.localeOf(context).toString(),
    );

    final AsyncValue<BalanceAmount?> amount;
    switch (displayMode) {
      case WalletDisplayMode.fiat:
        amount = _toAmount(
          ref.watch(totalWalletValueProvider),
          (value) => BalanceAmount(
            prefix: currencyIcon,
            digits: numberFormat.format(value),
            value: value,
            format: numberFormat.format,
          ),
        );
      case WalletDisplayMode.bitcoin:
        amount = _toAmount(
          ref.watch(totalWalletBitcoinProvider),
          (value) => BalanceAmount(
            digits: value.toStringAsFixed(8),
            suffix: 'BTC',
            value: value,
            format: (count) => count.toStringAsFixed(8),
          ),
        );
      case WalletDisplayMode.satoshis:
        amount = _toAmount(
          ref.watch(totalWalletSatoshisProvider),
          (value) => BalanceAmount(
            digits: SatsInputFormatter.formatValue(value.toInt()),
            suffix: value == BigInt.one ? 'sat' : 'sats',
            value: value.toDouble(),
            format: (count) => SatsInputFormatter.formatValue(count.round()),
          ),
        );
    }

    final variation = ref.watch(totalWalletVariationProvider);

    return BalanceHeroView(
      amount: amount,
      mode: displayMode,
      isHidden: isHidden,
      variation: variation.whenData(
        (either) => either.fold((_) => null, (value) => value),
      ),
      showPendingPix: _hasPendingPix(context, ref),
      onToggleVisibility: () => ref.read(isVisibleProvider.notifier).toggle(),
      onCycleMode: () =>
          ref.read(walletDisplayModeProvider.notifier).state = displayMode.next,
      onPendingPixTap: () => context.go('/asset'),
    );
  }

  /// Maps a provider value to an amount. A failed value maps to null.
  AsyncValue<BalanceAmount?> _toAmount<T>(
    AsyncValue<Either<String, T>> value,
    BalanceAmount Function(T value) format,
  ) {
    return value.whenData(
      (either) => either.fold((_) => null, (total) => format(total)),
    );
  }

  /// The pending PIX badge shows only on `/home` and only when deposits are
  /// pending.
  bool _hasPendingPix(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    if (currentLocation != '/home') return false;
    final valuesToReceive = ref.watch(valuesToReceiveProvider);
    return valuesToReceive.maybeWhen(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: (result) =>
          result.fold((_) => false, (toReceive) => toReceive.isNotEmpty),
      orElse: () => false,
    );
  }
}

/// Shows the label, the amount, the change chip, and the visibility toggle.
///
/// Motion:
/// - Skeleton to content: cross-fade over [Motion.durationBase].
/// - Press on the amount: the amount scales to [Motion.pressScale].
/// - Tap on the amount (unit change) or on the eye (reveal): the new figure
///   counts up from 0 to its value over [Motion.durationCountUp] and comes
///   into focus. Only taps start a count-up, never a screen open or a price
///   update.
/// - Price update: [AnimatedAmount] on the digits only.
/// - Visibility: cross-fade between digits and mask over
///   [Motion.durationFast].
///
/// Reduced motion removes all of these animations.
class BalanceHeroView extends StatefulWidget {
  const BalanceHeroView({
    super.key,
    required this.amount,
    required this.mode,
    required this.isHidden,
    required this.variation,
    required this.onToggleVisibility,
    required this.onCycleMode,
    this.showPendingPix = false,
    this.onPendingPixTap,
  });

  /// The balance. Null data means that the balance is not available.
  final AsyncValue<BalanceAmount?> amount;

  /// The display unit. A change of unit cross-fades.
  final Object mode;

  final bool isHidden;

  /// The change of the total, in percent. Null data hides the chip.
  final AsyncValue<double?> variation;

  final VoidCallback onToggleVisibility;
  final VoidCallback onCycleMode;
  final bool showPendingPix;
  final VoidCallback? onPendingPixTap;

  @override
  State<BalanceHeroView> createState() => _BalanceHeroViewState();
}

class _BalanceHeroViewState extends State<BalanceHeroView> {
  /// Number of taps that asked for a count-up.
  int _countRequest = 0;

  /// Last request that a count-up used. A request is used once.
  int _usedRequest = 0;

  /// Expires a request when no new figure shows soon after the tap, for
  /// example when the next unit has no value yet. A late value then shows
  /// without a count-up.
  Timer? _requestExpiry;

  AsyncValue<BalanceAmount?> get amount => widget.amount;
  Object get mode => widget.mode;
  bool get isHidden => widget.isHidden;
  AsyncValue<double?> get variation => widget.variation;

  void _requestCountUp() {
    setState(() => _countRequest++);
    _requestExpiry?.cancel();
    _requestExpiry = Timer(
      Motion.durationCountUp * 2,
      () => _usedRequest = _countRequest,
    );
  }

  /// Uses [request] once. Returns false when it was used or expired.
  bool _useRequest(int request) {
    if (request <= _usedRequest) return false;
    _usedRequest = request;
    return true;
  }

  void _onAmountTap() {
    _requestCountUp();
    widget.onCycleMode();
  }

  void _onVisibilityTap() {
    // Only a reveal shows a new figure.
    if (widget.isHidden) _requestCountUp();
    widget.onToggleVisibility();
  }

  @override
  void dispose() {
    _requestExpiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    final labelStyle = context.textTheme.bodyMedium?.copyWith(
      color: colors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(t.wallet_title, style: labelStyle)),
            if (widget.showPendingPix)
              _PendingPixBadge(
                label: t.pix_hub_pending_deposits,
                onTap: widget.onPendingPixTap,
              ),
            _VisibilityButton(
              isHidden: isHidden,
              tooltip: isHidden ? t.wallet_balance_show : t.wallet_balance_hide,
              onPressed: _onVisibilityTap,
            ),
          ],
        ),
        _buildAmount(context, t),
        const SizedBox(height: 8),
        _buildVariation(context),
      ],
    );
  }

  Widget _buildAmount(BuildContext context, AppLocalizations t) {
    final reduced = Motion.isReduced(context);
    final digitsStyle = context.textTheme.displayLarge?.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.8,
      height: 1.15,
    );
    final mutedStyle = digitsStyle?.copyWith(
      color: context.colors.textSecondary,
    );

    final String semanticsValue;
    final Widget content;
    if (amount.isLoading && !amount.hasValue) {
      semanticsValue = '';
      content = const SkeletonShimmer(
        key: ValueKey('loading'),
        child: SkeletonBox(width: 200, height: 44, radius: 12),
      );
    } else if (amount.valueOrNull case final value?) {
      semanticsValue = isHidden ? t.wallet_balance_hidden : value.fullText;
      content = FittedBox(
        key: const ValueKey('data'),
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (value.prefix.isNotEmpty) ...[
              Text(value.prefix, style: mutedStyle),
              const SizedBox(width: 8),
            ],
            AnimatedSwitcher(
              duration: Motion.of(context, Motion.durationFast),
              switchInCurve: Motion.curveMove,
              switchOutCurve: Motion.curveMove,
              layoutBuilder: _startAlignedLayout,
              child: isHidden
                  ? Text(
                      balanceMask,
                      key: const ValueKey('mask'),
                      style: digitsStyle,
                    )
                  : _BalanceDigits(
                      key: const ValueKey('digits'),
                      amount: value,
                      mode: mode,
                      style: digitsStyle,
                      countRequest: _countRequest,
                      useRequest: _useRequest,
                    ),
            ),
            if (value.suffix.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(value.suffix, style: mutedStyle),
            ],
          ],
        ),
      );
    } else {
      semanticsValue = 'N/A';
      content = Text('N/A', key: const ValueKey('error'), style: digitsStyle);
    }

    return Semantics(
      button: true,
      label: [
        t.wallet_title,
        semanticsValue,
      ].where((part) => part.isNotEmpty).join(', '),
      hint: t.wallet_balance_change_unit_hint,
      onTap: _onAmountTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onAmountTap,
        // A light press: the amount sinks a little under the finger.
        child: PressScale(
          child: AnimatedSwitcher(
            duration: reduced ? Duration.zero : Motion.durationBase,
            switchInCurve: Motion.curveMove,
            switchOutCurve: Motion.curveMove,
            layoutBuilder: _startAlignedLayout,
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildVariation(BuildContext context) {
    final Widget chip;
    if (variation.isLoading && !variation.hasValue) {
      chip = const LoadingChangeChip(key: ValueKey('loading'));
    } else {
      final value = variation.valueOrNull;
      // A change that shows as 0,00% shows no chip.
      chip = value == null || ChangeChip.isFlat(value)
          ? const SizedBox.shrink(key: ValueKey('none'))
          : ChangeChip(key: const ValueKey('chip'), percentage: value);
    }
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.durationBase),
      switchInCurve: Motion.curveMove,
      switchOutCurve: Motion.curveMove,
      layoutBuilder: _startAlignedLayout,
      child: chip,
    );
  }

  static Widget _startAlignedLayout(Widget? current, List<Widget> previous) {
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [...previous, if (current != null) current],
    );
  }
}

/// The digits of the balance.
///
/// At rest, it shows [AnimatedAmount]: a price update slides the digits.
/// When a new [countRequest] arrives and [useRequest] accepts it, the
/// figure counts up from 0 to its value over [Motion.durationCountUp] with
/// [Motion.curveEnter], so it never overshoots. In the first half of the
/// count, the digits come into focus from a light blur and a lower opacity.
/// The final figure reserves its width, so the row does not grow while the
/// figure counts.
///
/// With reduced motion, the figure shows at once.
class _BalanceDigits extends StatefulWidget {
  const _BalanceDigits({
    super.key,
    required this.amount,
    required this.mode,
    required this.style,
    required this.countRequest,
    required this.useRequest,
  });

  final BalanceAmount amount;
  final Object mode;
  final TextStyle? style;
  final int countRequest;
  final bool Function(int request) useRequest;

  @override
  State<_BalanceDigits> createState() => _BalanceDigitsState();
}

class _BalanceDigitsState extends State<_BalanceDigits>
    with SingleTickerProviderStateMixin {
  /// Blur at the start of the count, in logical pixels.
  static const double _startBlur = 3;

  /// Opacity at the start of the count.
  static const double _startOpacity = 0.5;

  late final AnimationController _count = AnimationController(
    vsync: this,
    duration: Motion.durationCountUp,
  )..addStatusListener(_onCountStatus);
  late final CurvedAnimation _progress = CurvedAnimation(
    parent: _count,
    curve: Motion.curveEnter,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // A reveal builds new digits, so the first build can start a count.
    _maybeCount();
  }

  @override
  void didUpdateWidget(_BalanceDigits oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countRequest != widget.countRequest) _maybeCount();
  }

  void _maybeCount() {
    if (widget.countRequest == 0) return;
    if (!widget.useRequest(widget.countRequest)) return;
    if (widget.amount.format == null || Motion.isReduced(context)) return;
    _count.forward(from: 0);
  }

  void _onCountStatus(AnimationStatus status) {
    // Back to the resting digits at the end of the count.
    if (status == AnimationStatus.completed && mounted) setState(() {});
  }

  @override
  void dispose() {
    _progress.dispose();
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.amount;
    final format = amount.format;
    if (!_count.isAnimating || format == null) {
      return AnimatedAmount(
        text: amount.digits,
        value: amount.value,
        mode: widget.mode,
        style: widget.style,
      );
    }

    final style = widget.style?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final color = style?.color ?? DefaultTextStyle.of(context).style.color;

    return AnimatedBuilder(
      animation: _count,
      builder: (context, _) {
        // Focus completes in the first half of the count.
        final focus = (_count.value * 2).clamp(0.0, 1.0);
        final blur = _startBlur * (1 - focus);
        final opacity = _startOpacity + (1 - _startOpacity) * focus;
        return Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            // Keeps the width of the final figure.
            Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Text(amount.digits, style: style, maxLines: 1),
            ),
            ImageFiltered(
              enabled: blur > 0.05,
              imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Text(
                format(amount.value * _progress.value),
                style: style?.copyWith(
                  color: color?.withValues(alpha: opacity),
                ),
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Eye button that toggles the balance visibility.
///
/// The icon fades and scales from 0.8 to 1 over [Motion.durationFast].
class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({
    required this.isHidden,
    required this.tooltip,
    required this.onPressed,
  });

  final bool isHidden;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: context.colors.textSecondary,
      icon: AnimatedSwitcher(
        duration: Motion.of(context, Motion.durationFast),
        switchInCurve: Motion.curveMove,
        switchOutCurve: Motion.curveMove,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: Icon(
          isHidden ? Icons.visibility_off : Icons.visibility,
          key: ValueKey(isHidden),
          size: 22,
        ),
      ),
    );
  }
}

/// Badge for pending PIX deposits. A tap opens the holdings tab.
///
/// The badge pulses twice when it appears and then stays still. With
/// reduced motion, it does not pulse.
class _PendingPixBadge extends StatefulWidget {
  const _PendingPixBadge({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  State<_PendingPixBadge> createState() => _PendingPixBadgeState();
}

class _PendingPixBadgeState extends State<_PendingPixBadge>
    with SingleTickerProviderStateMixin {
  static const _pulseCount = 2;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationSlow,
    value: 1,
  );
  late final Animation<double> _scale = Tween(
    begin: 0.85,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Motion.curveMove));

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.isReduced(context)) return;
    // One pulse goes down and back up. The badge ends at full size.
    _controller
        .repeat(min: 0, max: 1, reverse: true, count: _pulseCount * 2)
        .whenComplete(() {
          if (mounted) _controller.value = 1;
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final warning = context.appColors.warning;
    // `excludeSemantics` drops the semantics of the ink below, so the node
    // carries the tap action itself.
    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: widget.onTap,
        radius: 24,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    'assets/icons/menu/navigation/pix.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(warning, BlendMode.srcIn),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: warning,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search,
                        size: 10,
                        color: context.colors.onPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
