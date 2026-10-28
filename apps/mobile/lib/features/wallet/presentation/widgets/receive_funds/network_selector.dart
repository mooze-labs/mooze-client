import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Shows the receive network of the selected asset.
///
/// An asset with one network shows a quiet line with the network and one
/// hint. An asset with more networks shows one selectable row per network.
/// The block cross-fades when the asset changes.
class NetworkSelector extends ConsumerWidget {
  const NetworkSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
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

    if (selectedAsset == null || availableNetworks.isEmpty) {
      return Text(
        t.receive_select_asset_first,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.textSecondary,
        ),
      );
    }

    final hint = _assetHint(t, selectedAsset);

    return SizeFadeSwitcher(
      alignment: AlignmentDirectional.topStart,
      child: KeyedSubtree(
        key: ValueKey(selectedAsset),
        child: availableNetworks.length == 1
            ? _SingleNetwork(network: availableNetworks.first, hint: hint)
            : _NetworkOptions(
                networks: availableNetworks,
                selectedNetwork: selectedNetwork,
                hint: hint,
                onSelect: (network) {
                  ref.read(selectedReceiveNetworkProvider.notifier).state =
                      network;
                  validationController.validateNetwork(network);
                },
              ),
      ),
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
// Shared label, subtitle, hint, and logo helpers.
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

/// One quiet line that tells why the asset uses this network.
///
/// Every asset except BTC receives on Liquid only. The L-BTC hint string
/// still names Lightning, which the app removed, so L-BTC uses the
/// Liquid-only hint.
String _assetHint(AppLocalizations t, Asset asset) => switch (asset) {
  Asset.btc => t.receive_asset_hint_btc,
  _ => t.receive_asset_hint_liquid_only(asset.name),
};

/// The network logo. The logos are SVG assets, like the asset logos.
class _NetworkLogo extends StatelessWidget {
  final NetworkType network;
  final double size;

  const _NetworkLogo({required this.network, required this.size});

  @override
  Widget build(BuildContext context) {
    final asset = switch (network) {
      NetworkType.bitcoin => 'assets/icons/asset/bitcoin.svg',
      NetworkType.liquid => 'assets/icons/asset/lbtc.svg',
      NetworkType.unknown => null,
    };
    if (asset == null) {
      return PixIcon(
        PixIcons.help,
        size: size,
        color: context.colors.textSecondary,
      );
    }
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Single network: a quiet line on the page. The asset fixes the
// network, so there is nothing to choose. The line confirms it.
// ─────────────────────────────────────────────────────────────────────

class _SingleNetwork extends StatelessWidget {
  final NetworkType network;
  final String hint;

  const _SingleNetwork({required this.network, required this.hint});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final subtitle = _subtitle(t, network);
    final name = subtitle.isEmpty
        ? _label(t, network)
        : '${_label(t, network)} · $subtitle';

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: _NetworkLogo(network: network, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.35,
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

// ─────────────────────────────────────────────────────────────────────
// More networks: one selectable glass row per network. The selected row
// has a brand border and a check, so the selection never depends on
// color alone.
// ─────────────────────────────────────────────────────────────────────

class _NetworkOptions extends StatelessWidget {
  final List<NetworkType> networks;
  final NetworkType? selectedNetwork;
  final String hint;
  final ValueChanged<NetworkType> onSelect;

  const _NetworkOptions({
    required this.networks,
    required this.selectedNetwork,
    required this.hint,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            t.receive_select_network,
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < networks.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _NetworkOptionRow(
            network: networks[i],
            isSelected: selectedNetwork == networks[i],
            onTap: () => onSelect(networks[i]),
          ),
        ],
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            hint,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _NetworkOptionRow extends StatelessWidget {
  final NetworkType network;
  final bool isSelected;
  final VoidCallback onTap;

  const _NetworkOptionRow({
    required this.network,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final primary = context.colors.primaryColor;
    final label = _label(t, network);
    final subtitle = _subtitle(t, network);
    const radius = BorderRadius.all(Radius.circular(16));

    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      label: subtitle.isEmpty ? label : '$label, $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        child: GlassPanel(
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: isSelected ? primary : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GlassStyle.of(context).lensFill,
                        border: Border.all(
                          color: AppSurfaces.hairline(context),
                        ),
                      ),
                      child: _NetworkLogo(network: network, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: context.textTheme.bodyLarge?.copyWith(
                              color: context.colors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      PixIcon(PixIcons.check, size: 20, color: primary),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
