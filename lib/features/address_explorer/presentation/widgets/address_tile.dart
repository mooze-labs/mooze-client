import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_utxo.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_status.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/formatters/utxo_amount_formatter.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';

class AddressTile extends StatefulWidget {
  final WalletAddress address;
  final bool highlight;

  const AddressTile({
    super.key,
    required this.address,
    this.highlight = false,
  });

  @override
  State<AddressTile> createState() => _AddressTileState();
}

class _AddressTileState extends State<AddressTile> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  Future<void> _copyAddress() async {
    await Clipboard.setData(ClipboardData(text: widget.address.address));
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    AppSnackBar.info(context, t.address_explorer_address_copied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context);
    final isUsed = widget.address.status == AddressStatus.used;
    final utxoCount = widget.address.utxos.length;
    final hasUtxos = utxoCount > 0;

    final borderColor = widget.highlight
        ? scheme.primary
        : scheme.outlineVariant.withValues(alpha: 0.35);
    final bg = widget.highlight
        ? scheme.primaryContainer.withValues(alpha: 0.30)
        : scheme.surface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: widget.highlight ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _toggleExpanded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _StatusDot(used: isUsed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _expanded
                                ? widget.address.address
                                : _truncate(widget.address.address),
                            maxLines: _expanded ? null : 1,
                            overflow: _expanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface,
                              height: _expanded ? 1.4 : 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _MetaLine(
                            isUsed: isUsed,
                            utxoCount: utxoCount,
                            utxos: widget.address.utxos,
                            theme: theme,
                            t: t,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      splashRadius: 22,
                      tooltip: t.address_explorer_address_copied,
                      onPressed: _copyAddress,
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 180),
                      turns: _expanded ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: _expanded && hasUtxos
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                t.address_explorer_utxo_count(utxoCount),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            for (final utxo in widget.address.utxos)
                              _UtxoRow(utxo: utxo, theme: theme),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _truncate(String s) {
    if (s.length <= 26) return s;
    return '${s.substring(0, 12)}…${s.substring(s.length - 8)}';
  }
}

class _StatusDot extends StatelessWidget {
  final bool used;
  const _StatusDot({required this.used});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = used ? _usedColor(scheme) : scheme.onSurfaceVariant;
    final fill = used ? color : color.withValues(alpha: 0.25);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: used ? null : Border.all(color: color, width: 1),
      ),
    );
  }

  static Color _usedColor(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark
          ? const Color(0xFF4ADE80)
          : const Color(0xFF16A34A);
}

class _MetaLine extends StatelessWidget {
  final bool isUsed;
  final int utxoCount;
  final List<AddressUtxo> utxos;
  final ThemeData theme;
  final AppLocalizations t;

  const _MetaLine({
    required this.isUsed,
    required this.utxoCount,
    required this.utxos,
    required this.theme,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final parts = <String>[
      isUsed
          ? t.address_explorer_status_used
          : t.address_explorer_status_unused,
      t.address_explorer_utxo_count(utxoCount),
      // One balance per asset — Liquid addresses can hold several.
      ...groupedBalances(utxos),
    ];
    return Text(
      parts.join(' • '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _UtxoRow extends StatelessWidget {
  final AddressUtxo utxo;
  final ThemeData theme;
  const _UtxoRow({required this.utxo, required this.theme});

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '•',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              shortOutpoint(utxo.outpoint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatUtxoAmount(utxo.chain, utxo.assetId, utxo.value),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
