import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_summary_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/receive_address_field.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:share_plus/share_plus.dart';

/// Shows the receive request as a QR code.
///
/// The QR code is the hero. The requested amount sits above it, and the
/// asset and network sit between them as one quiet pill.
///
/// The code holds the whole request, with its asset and amount, so a
/// wallet that scans it fills them in; a tap on it copies that request.
/// Below the code, a field holds the bare address, which every wallet and
/// exchange accepts when pasted, and a tap on it copies only that. Share is
/// the secondary action at the bottom, and sends the whole request.
class ReceiveQRScreen extends ConsumerStatefulWidget {
  final String qrData;
  final String displayAddress;
  final Asset asset;
  final NetworkType network;
  final double? amount;
  final String? description;

  const ReceiveQRScreen({
    super.key,
    required this.qrData,
    required this.displayAddress,
    required this.asset,
    required this.network,
    this.amount,
    this.description,
  });

  @override
  ConsumerState<ReceiveQRScreen> createState() => _ReceiveQRScreenState();
}

class _ReceiveQRScreenState extends ConsumerState<ReceiveQRScreen> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasDescription =
        widget.description != null && widget.description!.isNotEmpty;

    return PixScreenScaffold(
      title: t.receive_qr_title,
      bottomAction: _ShareButton(
        label: t.pix_hub_share,
        onPressed: _shareAddress,
      ),
      children: [
        if (widget.amount != null) ...[
          _RequestedAmount(amount: widget.amount!, asset: widget.asset),
          const SizedBox(height: 14),
        ],
        Center(
          child: _NetworkPill(
            asset: widget.asset,
            networkLabel: _networkLabel(),
          ),
        ),
        const SizedBox(height: 20),
        // The code grows with the screen, up to a size that still leaves
        // the address in view on a regular phone. Only the white tile takes
        // the tap, not the space beside it.
        MergeSemantics(
          child: Semantics(
            button: true,
            hint: t.pix_hub_copy,
            onTap: _copyRequest,
            child: GestureDetector(
              onTap: _copyRequest,
              child: PressScale(
                child: LayoutBuilder(
                  builder: (context, constraints) => PixQrPanel(
                    data: widget.qrData,
                    size: (constraints.maxWidth - 32).clamp(160.0, 248.0),
                    semanticLabel: t.pix_hub_method_qr,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ReceiveAddressField(
          label: t.receive_qr_address_title,
          address: _bareAddress(widget.displayAddress),
        ),
        if (hasDescription) ...[
          const SizedBox(height: 12),
          PixSummaryCard(
            entries: [
              PixSummaryEntry(
                _stripTrailingColon(t.receive_qr_description_label),
                widget.description!,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _shareAddress() async {
    HapticFeedback.selectionClick();
    await SharePlus.instance.share(ShareParams(text: widget.qrData));
  }

  /// Copies the whole request of the QR code, and says so: the field below
  /// copies something else, the bare address.
  Future<void> _copyRequest() async {
    final t = AppLocalizations.of(context);
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: widget.qrData));
    if (!mounted) return;
    AppSnackBar.success(context, t.receive_qr_request_copied);
  }

  String _networkLabel() {
    final t = AppLocalizations.of(context);
    return switch (widget.network) {
      NetworkType.bitcoin => t.receive_network_bitcoin_onchain,
      NetworkType.liquid => t.receive_network_liquid_network,
      NetworkType.unknown => t.receive_network_unknown,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────
// Sub-widgets — kept private to this file.
// ─────────────────────────────────────────────────────────────────────

/// The requested amount: large tabular digits with the muted ticker, and
/// the sats value below for bitcoin assets.
class _RequestedAmount extends StatelessWidget {
  final double amount;
  final Asset asset;

  const _RequestedAmount({required this.amount, required this.asset});

  @override
  Widget build(BuildContext context) {
    final isBtcLike = asset == Asset.btc || asset == Asset.lbtc;
    final assetStr = _formatAssetAmount(amount, isBtcLike);
    final satsStr = isBtcLike
        ? _formatSats((amount * 100000000).round())
        : null;
    const tabular = [FontFeature.tabularFigures()];

    return MergeSemantics(
      child: Column(
        children: [
          // A long amount scales down instead of overflowing.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  assetStr,
                  style: context.textTheme.displaySmall?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    fontFeatures: tabular,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  asset.ticker,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (satsStr != null) ...[
            const SizedBox(height: 2),
            Text(
              '$satsStr sats',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                fontFeatures: tabular,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatAssetAmount(double amount, bool isBtcLike) {
    final decimals = isBtcLike ? 8 : 6;
    var s = amount.toStringAsFixed(decimals);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s.isEmpty ? '0' : s;
  }

  static String _formatSats(int sats) {
    final s = sats.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

/// The asset logo, the ticker, and the network as one quiet glass pill.
class _NetworkPill extends StatelessWidget {
  final Asset asset;
  final String networkLabel;

  const _NetworkPill({required this.asset, required this.networkLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: GlassStyle.of(context).lensFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            asset.iconPath,
            width: 18,
            height: 18,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${asset.ticker} · $networkLabel',
              textAlign: TextAlign.center,
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Neutral share button with the share icon. The brand pink stays off the
/// screen, because the copy field and the QR code are the main content.
class _ShareButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ShareButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textPrimary;
    return PressScale(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 55),
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: color,
            backgroundColor: GlassStyle.of(context).lensFill,
            minimumSize: const Size.fromHeight(55),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppSurfaces.hairline(context)),
            ),
            // The same size and weight as the label of the primary button.
            textStyle: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: PixIcon(PixIcons.share, size: 20, color: color),
          label: Text(label),
        ),
      ),
    );
  }
}

/// The address of a payment request: without its `bitcoin:`,
/// `liquidnetwork:` or `liquid:` scheme, and without the query that carries
/// the asset, the amount, and the message. A bare address stays as it is.
String _bareAddress(String request) {
  var address = request.trim();
  final lower = address.toLowerCase();
  for (final scheme in const ['bitcoin:', 'liquidnetwork:', 'liquid:']) {
    if (lower.startsWith(scheme)) {
      address = address.substring(scheme.length);
      break;
    }
  }
  final query = address.indexOf('?');
  return query == -1 ? address : address.substring(0, query);
}

/// Some l10n strings include a trailing ":" baked into the value
/// (e.g. "Amount:"). Strip it so we can render the label without
/// punctuation noise.
String _stripTrailingColon(String s) =>
    s.endsWith(':') ? s.substring(0, s.length - 1) : s;
