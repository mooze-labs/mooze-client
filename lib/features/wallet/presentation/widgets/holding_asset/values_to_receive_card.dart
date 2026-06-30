import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/user/providers/values_to_receive_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class ValuesToReceiveCard extends ConsumerStatefulWidget {
  const ValuesToReceiveCard({super.key});

  @override
  ConsumerState<ValuesToReceiveCard> createState() =>
      _ValuesToReceiveCardState();
}

class _ValuesToReceiveCardState extends ConsumerState<ValuesToReceiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
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
        AnimatedBuilder(
          animation: pulse,
          builder: (context, child) {
            return Opacity(opacity: 0.55 + 0.45 * pulse.value, child: child);
          },
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 1,
      color:
          isDark
              ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
    );
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : cs.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            isDark
                ? Border.all(color: cs.onSurface.withValues(alpha: 0.06))
                : null,
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
      ),
      child: child,
    );
  }
}
