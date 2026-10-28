import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/user/providers/values_to_receive_provider.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class ValuesToReceiveCard extends ConsumerStatefulWidget {
  const ValuesToReceiveCard({super.key});

  @override
  ConsumerState<ValuesToReceiveCard> createState() =>
      _ValuesToReceiveCardState();
}

class _ValuesToReceiveCardState extends ConsumerState<ValuesToReceiveCard>
    with SingleTickerProviderStateMixin {
  /// Number of pulses when the card appears. The icon then stays still, so
  /// the screen has no endless loop.
  static const _pulseCount = 2;

  // One pulse fades the icon down and back up. Two pulses take 3.2 s.
  late final AnimationController _pulseController = AnimationController(
    duration: Motion.durationCelebrate,
    vsync: this,
    value: 1,
  );
  late final CurvedAnimation _pulse = CurvedAnimation(
    parent: _pulseController,
    curve: Motion.curveMove,
  );
  bool _pulsed = false;

  /// Pulses the icon once per mount, when the card first shows. With
  /// reduced motion, the icon stays still.
  void _pulseOnFirstShow() {
    if (_pulsed) return;
    _pulsed = true;
    if (Motion.isReduced(context)) return;
    // Start after the frame: the call comes from build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pulseController
          .repeat(min: 0, max: 1, reverse: true, count: _pulseCount * 2)
          .whenComplete(() {
            if (mounted) _pulseController.value = 1;
          });
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final valuesToReceiveAsync = ref.watch(valuesToReceiveProvider);
    final totalValueAsync = ref.watch(totalValueToReceiveProvider);
    final currencyIcon = ref.watch(currencyControllerProvider.notifier).icon;

    return valuesToReceiveAsync.when(
      data:
          (result) => result.fold((_) => const SizedBox.shrink(), (
            toReceiveList,
          ) {
            if (toReceiveList.isEmpty) return const SizedBox.shrink();
            _pulseOnFirstShow();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SoftCard(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      pulse: _pulse,
                      title: t.wallet_holding_pending_payments_title,
                      totalChild: totalValueAsync.when(
                        data:
                            (total) => Text(
                              t.wallet_holding_pending_payments_total(
                                currencyIcon,
                                total.toStringAsFixed(2),
                              ),
                              style: Theme.of(
                                context,
                              ).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                        loading:
                            () => Text(
                              t.wallet_holding_calculating,
                              style: Theme.of(
                                context,
                              ).textTheme.labelMedium?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Hairline(),
                    const SizedBox(height: 10),
                    for (var i = 0; i < toReceiveList.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          top: i == 0 ? 0 : 6,
                          bottom: 6,
                        ),
                        child: _PendingRow(
                          iconPath: toReceiveList[i].asset.iconPath,
                          name: toReceiveList[i].asset.name,
                          value: toReceiveList[i].formattedValue,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _Header extends StatelessWidget {
  final Animation<double> pulse;
  final String title;
  final Widget totalChild;

  const _Header({
    required this.pulse,
    required this.title,
    required this.totalChild,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.55, end: 1.0).animate(pulse),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.14),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.schedule_rounded, color: cs.primary, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              totalChild,
            ],
          ),
        ),
      ],
    );
  }
}

class _Hairline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppSurfaces.hairline(context));
  }
}

class _PendingRow extends StatelessWidget {
  final String iconPath;
  final String name;
  final String value;

  const _PendingRow({
    required this.iconPath,
    required this.name,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              name,
              style: theme.textTheme.labelMedium?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        // const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    // The shared panel surface of the main screens.
    return Container(
      padding: padding,
      decoration: AppSurfaces.panel(context),
      child: child,
    );
  }
}
