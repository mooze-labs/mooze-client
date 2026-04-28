import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_match.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_status.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

class AddressOwnershipResult extends StatelessWidget {
  final AddressMatch match;

  const AddressOwnershipResult({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (!match.isOwned) {
      return _NotOwnedBanner(
        title: t.address_ownership_not_owned_title,
        address: _truncate(match.address),
        theme: theme,
      );
    }

    final chainLabel = match.chain == AddressChain.bitcoin
        ? t.address_ownership_chain_bitcoin
        : t.address_ownership_chain_liquid;
    final isUsed = match.status == AddressStatus.used;

    return _OwnedCard(
      title: t.address_ownership_owned_title,
      typeLabel: t.address_ownership_field_type,
      typeValue: chainLabel,
      utxosLabel: t.address_ownership_field_utxos,
      utxosValue: match.utxoCount.toString(),
      usedLabel: t.address_ownership_field_used,
      usedValue: isUsed ? t.address_ownership_yes : t.address_ownership_no,
      address: _truncate(match.address),
      theme: theme,
    );
  }

  static String _truncate(String address, {int prefix = 14, int suffix = 10}) {
    if (address.length <= prefix + suffix + 3) return address;
    return '${address.substring(0, prefix)}…${address.substring(address.length - suffix)}';
  }
}

class _NotOwnedBanner extends StatelessWidget {
  final String title;
  final String address;
  final ThemeData theme;

  const _NotOwnedBanner({
    required this.title,
    required this.address,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final muted = scheme.error.withValues(alpha: 0.85);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.cancel_rounded, color: muted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFamily: 'monospace',
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

class _OwnedCard extends StatelessWidget {
  final String title;
  final String typeLabel;
  final String typeValue;
  final String utxosLabel;
  final String utxosValue;
  final String usedLabel;
  final String usedValue;
  final String address;
  final ThemeData theme;

  const _OwnedCard({
    required this.title,
    required this.typeLabel,
    required this.typeValue,
    required this.utxosLabel,
    required this.utxosValue,
    required this.usedLabel,
    required this.usedValue,
    required this.address,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final success = _successColor(scheme);
    final successSurface = success.withValues(alpha: 0.10);
    final successBorder = success.withValues(alpha: 0.35);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: successSurface,
        border: Border.all(color: successBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: success, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: typeLabel, value: typeValue, theme: theme),
          const SizedBox(height: 6),
          _DetailRow(label: utxosLabel, value: utxosValue, theme: theme),
          const SizedBox(height: 6),
          _DetailRow(label: usedLabel, value: usedValue, theme: theme),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _successColor(ColorScheme scheme) {
    return scheme.brightness == Brightness.dark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF16A34A);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
