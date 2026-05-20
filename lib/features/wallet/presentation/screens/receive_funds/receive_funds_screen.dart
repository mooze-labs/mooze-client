import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/amount_field_receive.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/description_field_receive.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/generate_qr_button.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/network_selector.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_providers.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class ReceiveFundsScreen extends ConsumerWidget {
  const ReceiveFundsScreen({super.key});

  void _clearProviders(WidgetRef ref) {
    ref.invalidate(receiveAmountProvider);
    ref.invalidate(receiveAssetValueProvider);
    ref.invalidate(receiveSatsValueProvider);
    ref.invalidate(receiveFiatValueProvider);
    ref.invalidate(receiveDescriptionProvider);
    ref.invalidate(selectedReceiveAssetProvider);
    ref.invalidate(selectedReceiveNetworkProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _clearProviders(ref);
      },
      child: PlatformSafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(t.receive_title),
            leading: IconButton(
              onPressed: () {
                _clearProviders(ref);
                context.pop();
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            actions: [
              OfflineIndicator(
                onTap: () => OfflinePriceInfoOverlay.show(context),
              ),
              IconButton(
                onPressed: () => _showInfoSheet(context),
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).padding.bottom + 112,
                  ),
                  child: const _GroupedSurface(
                    children: [
                      _Section(child: AssetSelectorReceive()),
                      _SoftDivider(),
                      _Section(child: NetworkSelector()),
                      _SoftDivider(),
                      _Section(child: AmountFieldReceive()),
                      _SoftDivider(),
                      _Section(child: DescriptionFieldReceive()),
                    ],
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _StickyActionBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoSheet(BuildContext context) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InfoSheet(
        title: t.receive_info_title,
        steps: [
          (t.receive_info_step1_title, t.receive_info_step1_desc),
          (t.receive_info_step2_title, t.receive_info_step2_desc),
          (t.receive_info_step3_title, t.receive_info_step3_desc),
        ],
        hint: t.receive_info_close_hint,
      ),
    );
  }
}

class _GroupedSurface extends StatelessWidget {
  final List<Widget> children;
  const _GroupedSurface({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.45)
              : theme.colorScheme.outline.withValues(alpha: 0.55),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: children),
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;
  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: child,
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? theme.colorScheme.outlineVariant.withValues(alpha: 0.35)
          : theme.colorScheme.outline.withValues(alpha: 0.45),
    );
  }
}

class _StickyActionBar extends StatelessWidget {
  const _StickyActionBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Soft top fade so scroll content blurs into the bar instead of
        // crashing into a hard edge. Uses the scaffold background so the
        // solid section below is visually identical to the page bg in
        // both light and dark themes — no seam, no "panel" effect.
        IgnorePointer(
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  bg.withValues(alpha: 0.0),
                  bg,
                ],
              ),
            ),
          ),
        ),
        Container(
          color: bg,
          padding: EdgeInsets.fromLTRB(16, 4, 16, 12 + bottomInset),
          child: const GenerateQRButton(),
        ),
      ],
    );
  }
}

class _InfoSheet extends StatelessWidget {
  final String title;
  final List<(String, String)> steps;
  final String hint;

  const _InfoSheet({
    required this.title,
    required this.steps,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PlatformSafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < steps.length; i++) ...[
              _InfoStep(
                index: i + 1,
                title: steps[i].$1,
                description: steps[i].$2,
              ),
              if (i < steps.length - 1) const SizedBox(height: 14),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  final int index;
  final String title;
  final String description;

  const _InfoStep({
    required this.index,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
