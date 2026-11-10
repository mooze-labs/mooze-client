import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_match.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_utxo.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_status.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/formatters/utxo_amount_formatter.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class AddressOwnershipResult extends StatelessWidget {
  final AddressMatch match;

  const AddressOwnershipResult({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (!match.isOwned) {
      return _NotOwnedBanner(
        title: t.address_ownership_not_owned_title,
        address: _truncate(match.address),
      );
    }

    return _OwnedCard(match: match);
  }

  static String _truncate(String address, {int prefix = 14, int suffix = 10}) {
    if (address.length <= prefix + suffix + 3) return address;
    return '${address.substring(0, prefix)}…${address.substring(address.length - suffix)}';
  }
}

const List<String> _monoFallback = ['Menlo', 'Courier'];
const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

/// Address that is not from this wallet: one glass row with a small
/// negative signal.
class _NotOwnedBanner extends StatelessWidget {
  final String title;
  final String address;

  const _NotOwnedBanner({required this.title, required this.address});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tt = context.textTheme;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.cancel_rounded, color: colors.negativeColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: tt.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontFamily: 'monospace',
                    fontFamilyFallback: _monoFallback,
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

/// Address of this wallet: one glass panel whose rows are split by
/// hairlines. The positive color shows only as the header icon.
class _OwnedCard extends StatelessWidget {
  final AddressMatch match;

  const _OwnedCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    final tt = context.textTheme;

    final chainLabel = match.chain == AddressChain.bitcoin
        ? t.address_ownership_chain_bitcoin
        : t.address_ownership_chain_liquid;
    final isUsed = match.status == AddressStatus.used;
    final hasUtxos = match.utxos.isNotEmpty;

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.positiveColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.address_ownership_owned_title,
                    style: tt.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const PanelDivider(indent: 16),
          _DetailRow(label: t.address_ownership_field_type, value: chainLabel),
          const PanelDivider(indent: 16),
          _DetailRow(
            label: t.address_ownership_field_utxos,
            value: match.utxoCount.toString(),
          ),
          const PanelDivider(indent: 16),
          _DetailRow(
            label: t.address_ownership_field_used,
            value: isUsed ? t.address_ownership_yes : t.address_ownership_no,
          ),
          if (hasUtxos) ...[
            const PanelDivider(indent: 16),
            _BalanceSection(utxos: match.utxos),
          ],
          const PanelDivider(indent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Text(
              AddressOwnershipResult._truncate(match.address),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontFamilyFallback: _monoFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceSection extends StatelessWidget {
  final List<AddressUtxo> utxos;

  const _BalanceSection({required this.utxos});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    final tt = context.textTheme;

    // Group by asset — a Liquid address can hold several at once.
    final groups = groupUtxosByAsset(utxos);

    final rows = <Widget>[];
    groups.forEach((_, group) {
      final total = group.fold<BigInt>(BigInt.zero, (s, u) => s + u.value);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            formatUtxoAmount(group.first.chain, group.first.assetId, total),
            style: tt.bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFeatures: _tabular,
            ),
          ),
        ),
      );
      // Per-UTXO breakdown only when the asset spans multiple outputs.
      if (group.length > 1) {
        for (final u in group) {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shortOutpoint(u.outpoint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontFamilyFallback: _monoFallback,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatUtxoAmount(u.chain, u.assetId, u.value),
                    style: tt.bodySmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.address_ownership_field_balance,
            style: tt.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          ...rows,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tt = context.textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              label,
              style: tt.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: tt.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: _tabular,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
