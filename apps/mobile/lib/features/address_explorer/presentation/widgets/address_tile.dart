import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_utxo.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_status.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/formatters/utxo_amount_formatter.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One address as a row of the address panel. Tapping the row expands it
/// to the full address and its UTXOs.
class AddressTile extends StatefulWidget {
  final WalletAddress address;
  final bool highlight;

  const AddressTile({super.key, required this.address, this.highlight = false});

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
    final colors = context.colors;
    final tt = context.textTheme;
    final t = AppLocalizations.of(context);
    final isUsed = widget.address.status == AddressStatus.used;
    final utxoCount = widget.address.utxos.length;
    final hasUtxos = utxoCount > 0;

    // The highlight fill is an ink decoration, so ripples paint above it.
    return Ink(
      color: widget.highlight ? GlassStyle.of(context).lensFill : null,
      child: Stack(
        children: [
          if (widget.highlight)
            Positioned(
              left: 0,
              top: 12,
              bottom: 12,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: colors.primaryColor,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(3),
                  ),
                ),
              ),
            ),
          InkWell(
            onTap: _toggleExpanded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _StatusDot(used: isUsed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
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
                                style: tt.bodyMedium?.copyWith(
                                  fontFamily: 'monospace',
                                  fontFamilyFallback: _monoFallback,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                  height: _expanded ? 1.4 : 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _MetaLine(
                                isUsed: isUsed,
                                utxoCount: utxoCount,
                                utxos: widget.address.utxos,
                                t: t,
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        tooltip: t.address_explorer_address_copied,
                        onPressed: _copyAddress,
                      ),
                      AnimatedRotation(
                        duration: Motion.of(context, Motion.durationFast),
                        curve: Motion.curveMove,
                        turns: _expanded ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: Motion.of(context, Motion.durationBase),
                  curve: Motion.curveMove,
                  alignment: Alignment.topCenter,
                  child: _expanded && hasUtxos
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(36, 0, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  t.address_explorer_utxo_count(utxoCount),
                                  style: tt.labelMedium?.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              for (final utxo in widget.address.utxos)
                                _UtxoRow(utxo: utxo),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _truncate(String s) {
    if (s.length <= 26) return s;
    return '${s.substring(0, 12)}…${s.substring(s.length - 8)}';
  }
}

const List<String> _monoFallback = ['Menlo', 'Courier'];

/// Small status signal: a filled positive dot for a used address, a hollow
/// ring for an unused one.
class _StatusDot extends StatelessWidget {
  final bool used;
  const _StatusDot({required this.used});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: used ? colors.positiveColor : Colors.transparent,
        shape: BoxShape.circle,
        border: used
            ? null
            : Border.all(color: colors.textTertiary, width: 1.2),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final bool isUsed;
  final int utxoCount;
  final List<AddressUtxo> utxos;
  final AppLocalizations t;

  const _MetaLine({
    required this.isUsed,
    required this.utxoCount,
    required this.utxos,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      isUsed
          ? t.address_explorer_status_used
          : t.address_explorer_status_unused,
      t.address_explorer_utxo_count(utxoCount),
      // One balance per asset — Liquid addresses can hold several.
      ...groupedBalances(utxos),
    ];
    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colors.textSecondary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _UtxoRow extends StatelessWidget {
  final AddressUtxo utxo;
  const _UtxoRow({required this.utxo});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tt = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              shortOutpoint(utxo.outpoint),
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
            formatUtxoAmount(utxo.chain, utxo.assetId, utxo.value),
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
