import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class NetworkSelector extends ConsumerWidget {
  const NetworkSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selectedNetwork = ref.watch(selectedReceiveNetworkProvider);
    final selectedAsset = ref.watch(selectedReceiveAssetProvider);
    final validationController = ref.read(
      receiveValidationControllerProvider.notifier,
    );

    final availableNetworks = _getAvailableNetworks(selectedAsset);

    // Auto-select the first available network when nothing is selected
    // yet (initial load) or when the currently-selected network isn't
    // compatible with the new asset. Expanded from the prior
    // "selectedNetwork != null && !contains" check so single-network
    // assets get their network locked in without any user interaction.
    if (availableNetworks.isNotEmpty &&
        (selectedNetwork == null ||
            !availableNetworks.contains(selectedNetwork))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final first = availableNetworks.first;
        ref.read(selectedReceiveNetworkProvider.notifier).state = first;
        validationController.validateNetwork(first);
      });
    }

    if (availableNetworks.isEmpty) {
      return Text(
        t.receive_select_asset_first,
        style: theme.textTheme.bodySmall?.copyWith(
          color: context.colors.textSecondary,
        ),
      );
    }

    final isSingleNetwork = availableNetworks.length == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Single-network assets get a self-describing info row
        // ("Bitcoin · On-chain") so the section label would just be
        // noise — drop it entirely there.
        if (!isSingleNetwork) ...[
          Text(
            t.receive_select_network,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child:
              isSingleNetwork
                  ? _NetworkInfoRow(
                    icon: _icon(availableNetworks.first),
                    label: _label(t, availableNetworks.first),
                    subtitle: _subtitle(t, availableNetworks.first),
                  )
                  : _NetworkCardGrid(
                    networks: availableNetworks,
                    selectedNetwork: selectedNetwork,
                    onSelect: (network) {
                      ref.read(selectedReceiveNetworkProvider.notifier).state =
                          network;
                      validationController.validateNetwork(network);
                    },
                  ),
        ),
      ],
    );
  }

  List<NetworkType> _getAvailableNetworks(Asset? asset) {
    if (asset == null) return [];
    return switch (asset) {
      Asset.btc => [NetworkType.bitcoin],
      Asset.lbtc => [NetworkType.liquid],
      Asset.usdt => [NetworkType.liquid],
      Asset.depix => [NetworkType.liquid],
    };
  }
}

// ─────────────────────────────────────────────────────────────────────
// Shared label/subtitle/icon helpers — used by both the multi-network
// card grid and the single-network info row.
// ─────────────────────────────────────────────────────────────────────

String _label(AppLocalizations t, NetworkType n) => switch (n) {
  NetworkType.bitcoin => t.receive_network_label_bitcoin,
  NetworkType.liquid => t.receive_network_label_liquid,
  NetworkType.unknown => t.receive_network_unknown,
};

String _subtitle(AppLocalizations t, NetworkType n) => switch (n) {
  NetworkType.bitcoin => t.receive_network_subtitle_onchain,
  NetworkType.liquid => t.receive_network_subtitle_private,
  NetworkType.unknown => '',
};

IconData _icon(NetworkType n) => switch (n) {
  NetworkType.bitcoin => Icons.link_rounded,
  NetworkType.liquid => Icons.water_drop_outlined,
  NetworkType.unknown => Icons.help_outline_rounded,
};

// ─────────────────────────────────────────────────────────────────────
// Multi-network: side-by-side visual cards with a large icon bubble at
// the top, label, and subtitle.
// ─────────────────────────────────────────────────────────────────────

class _NetworkCardGrid extends StatelessWidget {
  final List<NetworkType> networks;
  final NetworkType? selectedNetwork;
  final ValueChanged<NetworkType> onSelect;

  const _NetworkCardGrid({
    required this.networks,
    required this.selectedNetwork,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cards = <Widget>[];
    for (var i = 0; i < networks.length; i++) {
      final n = networks[i];
      if (i > 0) cards.add(const SizedBox(width: 12));
      cards.add(
        Expanded(
          child: _NetworkCard(
            icon: _icon(n),
            label: _label(t, n),
            subtitle: _subtitle(t, n),
            isSelected: selectedNetwork == n,
            onTap: () => onSelect(n),
          ),
        ),
      );
    }
    // IntrinsicHeight keeps both cards the same height even when the
    // subtitles have different line counts at narrow widths.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards,
      ),
    );
  }
}

class _NetworkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _NetworkCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final borderColor =
        isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.08);

    final cardBg =
        isSelected
            ? cs.primary.withValues(alpha: 0.08)
            : cs.onSurface.withValues(alpha: 0.05);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CardIconBubble(icon: icon, isSelected: isSelected),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardIconBubble extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const _CardIconBubble({required this.icon, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 22,
        color: isSelected ? cs.onPrimary : cs.onSurface,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Single-network: compact, non-interactive info row. The network is
// implied by the asset (e.g. BTC ⇒ Bitcoin On-chain) so there's no
// selection to make — just confirm what's going to be used.
// ─────────────────────────────────────────────────────────────────────

class _NetworkInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _NetworkInfoRow({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                    letterSpacing: 0.2,
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
