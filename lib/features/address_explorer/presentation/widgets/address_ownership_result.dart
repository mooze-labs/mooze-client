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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context);

    if (!match.isOwned) {
      return _ResultCard(
        backgroundColor: scheme.errorContainer,
        foregroundColor: scheme.onErrorContainer,
        icon: Icons.cancel_outlined,
        title: t.address_ownership_not_owned_title,
        subtitle: _truncate(match.address),
      );
    }

    final chainLabel = match.chain == AddressChain.bitcoin
        ? t.address_ownership_chain_bitcoin
        : t.address_ownership_chain_liquid;
    final statusLabel = match.status == AddressStatus.used
        ? t.address_ownership_status_used
        : t.address_ownership_status_unused;
    final indexFragment = match.derivationIndex != null
        ? ' · ${t.address_ownership_index_label(match.derivationIndex!)}'
        : '';

    return _ResultCard(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      icon: Icons.verified_rounded,
      title: t.address_ownership_owned_title,
      subtitle: '$chainLabel · $statusLabel$indexFragment\n${_truncate(match.address)}',
    );
  }

  static String _truncate(String address, {int prefix = 16, int suffix = 12}) {
    if (address.length <= prefix + suffix + 3) return address;
    return '${address.substring(0, prefix)}…${address.substring(address.length - suffix)}';
  }
}

class _ResultCard extends StatelessWidget {
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String title;
  final String subtitle;

  const _ResultCard({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foregroundColor, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontFamily: 'monospace',
                    height: 1.4,
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
