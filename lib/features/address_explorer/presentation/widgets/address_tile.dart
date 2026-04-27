import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_utxo.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_status.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

class AddressTile extends StatelessWidget {
  final WalletAddress address;
  final bool highlight;

  const AddressTile({
    super.key,
    required this.address,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context);
    final isUsed = address.status == AddressStatus.used;
    final utxoCount = address.utxos.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: scheme.primary, width: 1.5)
            : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: _IndexBadge(index: address.derivationIndex, used: isUsed),
          title: Text(
            _truncate(address.address),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StatusBadge(used: isUsed, t: t),
                _UtxoBadge(count: utxoCount, t: t),
                if (address.receivedSats > BigInt.zero)
                  Text(
                    t.address_explorer_total_received(
                      _formatAmount(address.receivedSats),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.copy_outlined, size: 20),
            tooltip: t.address_explorer_address_copied,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: address.address));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.address_explorer_address_copied),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: SelectableText(
                address.address,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ),
            if (address.utxos.isNotEmpty) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.address_explorer_utxos_section,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              for (final utxo in address.utxos) _UtxoRow(utxo: utxo),
            ],
          ],
        ),
      ),
    );
  }

  static String _truncate(String s) {
    if (s.length <= 26) return s;
    return '${s.substring(0, 16)}…${s.substring(s.length - 8)}';
  }

  static String _formatAmount(BigInt sats) {
    // Group thousands with a thin space for readability.
    final s = sats.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf sats';
  }
}

class _IndexBadge extends StatelessWidget {
  final int index;
  final bool used;
  const _IndexBadge({required this.index, required this.used});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: used ? scheme.tertiary : scheme.primary,
      ),
      child: Text(
        '$index',
        style: TextStyle(
          color: used ? scheme.onTertiary : scheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool used;
  final AppLocalizations t;
  const _StatusBadge({required this.used, required this.t});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = used ? scheme.tertiary : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            used
                ? Icons.history_toggle_off_rounded
                : Icons.fiber_new_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            used
                ? t.address_explorer_status_used
                : t.address_explorer_status_unused,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _UtxoBadge extends StatelessWidget {
  final int count;
  final AppLocalizations t;
  const _UtxoBadge({required this.count, required this.t});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emphasised = count > 0;
    final color = emphasised ? scheme.secondary : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: emphasised ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        t.address_explorer_utxo_count(count),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _UtxoRow extends StatelessWidget {
  final AddressUtxo utxo;
  const _UtxoRow({required this.utxo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              utxo.outpoint,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatValue(utxo.value, utxo.assetId),
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  static String _formatValue(BigInt value, String? assetId) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return assetId == null ? '$buf sats' : buf.toString();
  }
}
