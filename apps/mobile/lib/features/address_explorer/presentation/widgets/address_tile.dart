import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_utxo.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/formatters/utxo_amount_formatter.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/widgets/address_details_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One address as a row of the address panel. Tapping the row opens the
/// address in an [AddressDetailsSheet], with its QR code and its UTXOs.
/// The copy button copies the address without leaving the list.
class AddressTile extends StatelessWidget {
  final WalletAddress address;
  final bool highlight;

  const AddressTile({super.key, required this.address, this.highlight = false});

  Future<void> _copyAddress(BuildContext context) async {
    final t = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: address.address));
    if (!context.mounted) return;
    AppSnackBar.info(context, t.address_explorer_address_copied);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tt = context.textTheme;
    final t = AppLocalizations.of(context);

    // The highlight fill is an ink decoration, so ripples paint above it.
    return Ink(
      color: highlight ? GlassStyle.of(context).lensFill : null,
      child: Stack(
        children: [
          if (highlight)
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
            onTap: () => showAddressDetailsSheet(context, address),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AddressStatusDot(used: address.isUsed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _truncate(address.address),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontFamilyFallback: _monoFallback,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _MetaLine(
                            isUsed: address.isUsed,
                            utxoCount: address.utxos.length,
                            utxos: address.utxos,
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
                    tooltip: t.address_explorer_full_address_copy,
                    onPressed: () => _copyAddress(context),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.textTertiary,
                  ),
                  const SizedBox(width: 10),
                ],
              ),
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
class AddressStatusDot extends StatelessWidget {
  final bool used;
  const AddressStatusDot({super.key, required this.used});

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
