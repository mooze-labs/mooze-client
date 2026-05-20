import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    return PlatformSafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).receive_qr_title),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildPaymentInfo(),
              const SizedBox(height: 16),
              _buildQRCode(),
              const SizedBox(height: 16),
              _buildAddressSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Payment info — flat panel, identity + (optional) hero amount +
  // (optional) description. Sections separated by hairline dividers,
  // not nested cards, so the visual weight stays low.
  // ─────────────────────────────────────────────────────────────────

  Widget _buildPaymentInfo() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasAmount = widget.amount != null;
    final hasDescription =
        widget.description != null && widget.description!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IdentityRow(asset: widget.asset, networkLabel: _networkLabel()),
          if (hasAmount) ...[
            const SizedBox(height: 14),
            _SoftHairline(),
            const SizedBox(height: 14),
            _AmountBlock(amount: widget.amount!, asset: widget.asset),
          ],
          if (hasDescription) ...[
            const SizedBox(height: 14),
            _SoftHairline(),
            const SizedBox(height: 14),
            _DescriptionBlock(text: widget.description!),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Address section — chunked monospace display + primary Copy /
  // secondary Share. Single soft surface; no nested boxes.
  // ─────────────────────────────────────────────────────────────────

  Widget _buildAddressSection() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = AppLocalizations.of(context);
    final isLightning = widget.network == NetworkType.lightning;
    final title = isLightning
        ? t.receive_qr_lightning_invoice
        : t.receive_qr_address_title;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconChip(
                icon: isLightning
                    ? Icons.bolt_rounded
                    : Icons.link_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AddressMono(text: _getCleanAddress()),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CopyButton(
                  isCopied: _isCopied,
                  onTap: _copyAddressToClipboard,
                  copyLabel: t.receive_qr_copy_address,
                  copiedLabel: t.receive_qr_copied,
                ),
              ),
              const SizedBox(width: 10),
              _ShareIconButton(onTap: _shareAddress),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PrettyQrView.data(data: widget.qrData),
    );
  }

  void _copyAddressToClipboard() async {
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: _getCleanAddress()));
    if (!mounted) return;
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  Future<void> _shareAddress() async {
    HapticFeedback.selectionClick();
    await SharePlus.instance.share(
      ShareParams(text: _getCleanAddress()),
    );
  }

  String _getCleanAddress() {
    return widget.amount != null ? widget.qrData : widget.displayAddress;
  }

  String _networkLabel() {
    final t = AppLocalizations.of(context);
    return switch (widget.network) {
      NetworkType.bitcoin => t.receive_network_bitcoin_onchain,
      NetworkType.lightning => t.receive_network_lightning_network,
      NetworkType.liquid => t.receive_network_liquid_network,
      NetworkType.unknown => t.receive_network_unknown,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────
// Sub-widgets — kept private to this file.
// ─────────────────────────────────────────────────────────────────────

class _IdentityRow extends StatelessWidget {
  final Asset asset;
  final String networkLabel;

  const _IdentityRow({required this.asset, required this.networkLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.onSurface.withValues(alpha: 0.06),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            asset.iconPath,
            width: 26,
            height: 26,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                asset.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                networkLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: context.colors.textSecondary,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountBlock extends StatelessWidget {
  final double amount;
  final Asset asset;

  const _AmountBlock({required this.amount, required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isBtcLike = asset == Asset.btc || asset == Asset.lbtc;
    final assetStr = _formatAssetAmount(amount, isBtcLike);
    final satsStr = isBtcLike
        ? _formatSats((amount * 100000000).round())
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _stripTrailingColon(t.receive_qr_amount_label),
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                assetStr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                asset.ticker,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (satsStr != null) ...[
          const SizedBox(height: 2),
          Text(
            '$satsStr sats',
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
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

class _DescriptionBlock extends StatelessWidget {
  final String text;
  const _DescriptionBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _stripTrailingColon(t.receive_qr_description_label),
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
        ),
      ],
    );
  }
}

/// Some l10n strings include a trailing ":" baked into the value
/// (e.g. "Amount:"). Strip it so we can render the label without
/// punctuation noise.
String _stripTrailingColon(String s) =>
    s.endsWith(':') ? s.substring(0, s.length - 1) : s;

class _SoftHairline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 1,
      color: isDark
          ? theme.colorScheme.outlineVariant.withValues(alpha: 0.25)
          : theme.colorScheme.outline.withValues(alpha: 0.25),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  const _IconChip({required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primary.withValues(alpha: 0.14),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: cs.primary),
    );
  }
}

/// Chunked monospace address renderer. Inserts narrow zero-width
/// space points every 6 characters so the text wraps cleanly inside
/// the row but stays one logical word for `Text`'s line-breaker. The
/// visible separation comes from a Wrap of small Text spans which
/// keeps long lightning invoices readable on narrow screens.
class _AddressMono extends StatelessWidget {
  final String text;
  const _AddressMono({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chunks = _chunk(text, 6);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: [
          for (final c in chunks)
            Text(
              c,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.2,
                letterSpacing: 0.4,
              ),
            ),
        ],
      ),
    );
  }

  static List<String> _chunk(String s, int size) {
    final out = <String>[];
    for (var i = 0; i < s.length; i += size) {
      out.add(s.substring(i, (i + size).clamp(0, s.length)));
    }
    return out;
  }
}

class _CopyButton extends StatelessWidget {
  final bool isCopied;
  final VoidCallback onTap;
  final String copyLabel;
  final String copiedLabel;

  const _CopyButton({
    required this.isCopied,
    required this.onTap,
    required this.copyLabel,
    required this.copiedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final positive = context.colors.positiveColor;
    final bg = isCopied ? positive : cs.primary;
    final fg = isCopied ? cs.surface : cs.onPrimary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: isCopied
                ? null
                : [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: Row(
              key: ValueKey(isCopied),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCopied
                      ? Icons.check_rounded
                      : Icons.copy_rounded,
                  size: 18,
                  color: fg,
                ),
                const SizedBox(width: 8),
                Text(
                  isCopied ? copiedLabel : copyLabel,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShareIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    return Material(
      color: cs.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? cs.outlineVariant.withValues(alpha: 0.45)
                  : cs.outline.withValues(alpha: 0.45),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.ios_share_rounded, size: 20, color: cs.onSurface),
        ),
      ),
    );
  }
}
