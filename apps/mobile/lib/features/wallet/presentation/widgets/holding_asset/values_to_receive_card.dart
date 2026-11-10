import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/user/providers/values_to_receive_provider.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The DePix payments on their way to the wallet, in a glass panel above
/// the holdings. The pending icon pulses twice when the card appears.
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
  //
  // Both are created in initState, not lazily. A card without values never
  // reads them, and the first read would then happen in dispose, where
  // creating the ticker looks up a deactivated element and throws.
  late final AnimationController _pulseController;
  late final CurvedAnimation _pulse;
  bool _pulsed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Motion.durationCelebrate,
      vsync: this,
      value: 1,
    );
    _pulse = CurvedAnimation(parent: _pulseController, curve: Motion.curveMove);
  }

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
    final currencyIcon = ref.watch(currencySymbolProvider);

    return valuesToReceiveAsync.when(
      data: (result) => result.fold((_) => const SizedBox.shrink(), (
        toReceiveList,
      ) {
        if (toReceiveList.isEmpty) return const SizedBox.shrink();
        _pulseOnFirstShow();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          // The glass panel of the holdings below it: the header, then one
          // row per payment, split by hairlines.
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: _Header(
                    pulse: _pulse,
                    title: t.wallet_holding_pending_payments_title,
                    totalChild: totalValueAsync.when(
                      data: (total) => Text(
                        t.wallet_holding_pending_payments_total(
                          currencyIcon,
                          NumberFormat(
                            '#,##0.00',
                            Localizations.localeOf(context).toString(),
                          ).format(total),
                        ),
                        style: context.textTheme.labelMedium?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      loading: () => Text(
                        t.wallet_holding_calculating,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                for (var i = 0; i < toReceiveList.length; i++) ...[
                  PanelDivider(indent: i == 0 ? 0 : _PendingRow.textInset),
                  _PendingRow(
                    iconPath: toReceiveList[i].asset.iconPath,
                    name: toReceiveList[i].asset.name,
                    value: toReceiveList[i].formattedValue,
                  ),
                ],
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

/// The pending icon, the title, and the total. The icon sits in a well of
/// the warning tone: the payments are on their way.
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.55, end: 1.0).animate(pulse),
          child: const PixIconWell(
            icon: PixIcons.pending,
            tone: PixTone.warning,
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
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colors.textPrimary,
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

/// One payment on its way: the coin, its name, and the value.
class _PendingRow extends StatelessWidget {
  final String iconPath;
  final String name;
  final String value;

  const _PendingRow({
    required this.iconPath,
    required this.name,
    required this.value,
  });

  static const double _iconSize = 24;

  /// Start of the text, where the hairline between rows begins.
  static const double textInset = 16 + _iconSize + 12;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          SvgPicture.asset(
            iconPath,
            width: _iconSize,
            height: _iconSize,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
