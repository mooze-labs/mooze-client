import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_utxo.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/formatters/utxo_amount_formatter.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/widgets/address_tile.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/receive_address_field.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Shows [address] in an [AddressDetailsSheet].
Future<void> showAddressDetailsSheet(
  BuildContext context,
  WalletAddress address,
) {
  return showFloatingGlassSheet<void>(
    context,
    builder: (_) => AddressDetailsSheet(address: address),
  );
}

/// One address of the wallet in a floating glass sheet.
///
/// The header names the chain and the derivation index. Below it, a pill
/// with the status, the QR code of the address, the full address that a
/// tap copies, and the UTXOs of the address. The content scrolls when it
/// does not fit, and the header stays in view.
class AddressDetailsSheet extends StatelessWidget {
  const AddressDetailsSheet({super.key, required this.address});

  final WalletAddress address;

  /// Smallest and largest side of the QR code.
  static const double _minQrSize = 160;
  static const double _maxQrSize = 232;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final chain = address.chain == AddressChain.bitcoin
        ? t.address_explorer_tab_onchain
        : t.address_explorer_tab_liquid;

    return GlassSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassSheetHeader(
            title: t.address_explorer_full_address_title,
            subtitle: t.address_explorer_search_match_at_index(
              chain,
              address.derivationIndex,
            ),
            leading: _ChainWell(chain: address.chain),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _StatusPill(address: address)),
                  const SizedBox(height: 16),
                  // The code grows with the sheet, up to a size that keeps
                  // the address in view on a regular phone.
                  LayoutBuilder(
                    builder: (context, constraints) => PixQrPanel(
                      data: address.address,
                      size: (constraints.maxWidth - 2 * PixQrPanel.margin)
                          .clamp(_minQrSize, _maxQrSize),
                      semanticLabel: t.pix_hub_method_qr,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ReceiveAddressField(
                    label: t.receive_qr_address_title,
                    address: address.address,
                  ),
                  if (address.utxos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _UtxoList(utxos: address.utxos),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A glass lens with the icon of the chain, as on the chain selector of the
/// address screen.
class _ChainWell extends StatelessWidget {
  const _ChainWell({required this.chain});

  final AddressChain chain;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GlassStyle.of(context).lensFill,
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: Icon(
        chain == AddressChain.bitcoin
            ? Icons.currency_bitcoin_rounded
            : Icons.water_drop_rounded,
        size: _size / 2,
        color: context.colors.textPrimary,
      ),
    );
  }
}

/// A quiet lens pill with the status dot, the status, and the number of
/// UTXOs.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.address});

  final WalletAddress address;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: GlassStyle.of(context).lensFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AddressStatusDot(used: address.isUsed),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: address.isUsed
                        ? t.address_explorer_status_used
                        : t.address_explorer_status_unused,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' · ${t.address_explorer_utxo_count(address.utxos.length)}',
                  ),
                ],
              ),
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The UTXOs of the address in a glass lens, one row each, split by
/// hairlines.
class _UtxoList extends StatelessWidget {
  const _UtxoList({required this.utxos});

  final List<AddressUtxo> utxos;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        color: GlassStyle.of(context).lensFill,
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Semantics(
              header: true,
              child: Text(
                t.address_explorer_utxo_count(utxos.length),
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          for (var i = 0; i < utxos.length; i++) ...[
            if (i > 0) const PanelDivider(indent: 14 + _UtxoRow.iconSize + 12),
            _UtxoRow(utxo: utxos[i]),
          ],
        ],
      ),
    );
  }
}

/// One UTXO: the icon of its asset, its outpoint, and its amount.
///
/// Liquid does not expose outpoints to the app, so a Liquid row names the
/// asset instead.
class _UtxoRow extends StatelessWidget {
  const _UtxoRow({required this.utxo});

  final AddressUtxo utxo;

  static const double iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final asset = assetForUtxo(utxo.chain, utxo.assetId);
    final hasOutpoint = utxo.outpoint.isNotEmpty;
    final textTheme = context.textTheme;

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final rowWidth = constraints.maxWidth;
            return Row(
              children: [
                if (asset != null)
                  SvgPicture.asset(
                    asset.iconPath,
                    width: iconSize,
                    height: iconSize,
                    excludeFromSemantics: true,
                  )
                else
                  Icon(
                    Icons.token_outlined,
                    size: iconSize,
                    color: context.colors.textSecondary,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasOutpoint
                        ? shortOutpoint(utxo.outpoint)
                        : asset?.name ?? shortAssetId(utxo.assetId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: hasOutpoint
                        ? textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontFamilyFallback: const ['Menlo', 'Courier'],
                            color: context.colors.textSecondary,
                          )
                        : textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // The amount keeps its full width, up to a share of the row;
                // with large text it wraps there, and never cuts.
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: rowWidth * 0.6),
                  child: Text(
                    formatUtxoAmount(utxo.chain, utxo.assetId, utxo.value),
                    textAlign: TextAlign.end,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
