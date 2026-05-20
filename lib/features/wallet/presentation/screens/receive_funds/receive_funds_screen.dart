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
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                20,
                16,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AssetSelectorReceive(),
                  SizedBox(height: 28),
                  NetworkSelector(),
                  SizedBox(height: 28),
                  AmountFieldReceive(),
                  SizedBox(height: 28),
                  DescriptionFieldReceive(),
                  SizedBox(height: 32),
                  GenerateQRButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoSheet(BuildContext context) {
    final t = AppLocalizations.of(context);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel:
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, _) => _FloatingInfoCard(
        title: t.receive_info_title,
        steps: [
          (t.receive_info_step1_title, t.receive_info_step1_desc),
          (t.receive_info_step2_title, t.receive_info_step2_desc),
          (t.receive_info_step3_title, t.receive_info_step3_desc),
        ],
        hint: t.receive_info_close_hint,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    );
  }
}

class _FloatingInfoCard extends StatelessWidget {
  final String title;
  final List<(String, String)> steps;
  final String hint;

  const _FloatingInfoCard({
    required this.title,
    required this.steps,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _CloseButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < steps.length; i++) ...[
                    _InfoStep(
                      index: i + 1,
                      title: steps[i].$1,
                      description: steps[i].$2,
                    ),
                    if (i < steps.length - 1) const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 16),
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
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.onSurface.withValues(alpha: 0.06),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
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
