import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'inline_copy_button.dart';

/// A label/value detail row of the transaction details panel. When [copyable] is set it owns the brief
/// "copied" feedback state itself, so the surrounding screen no longer has to
/// track which field was last copied.
class DetailRow extends StatefulWidget {
  final String label;
  final String value;
  final bool copyable;

  /// The raw value placed on the clipboard — defaults to [value] when omitted,
  /// letting callers display a truncated hash while copying the full one.
  final String? copyValue;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.copyable = false,
    this.copyValue,
  });

  @override
  State<DetailRow> createState() => _DetailRowState();
}

class _DetailRowState extends State<DetailRow> {
  bool _isCopied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.copyValue ?? widget.value));
    HapticFeedback.selectionClick();

    setState(() => _isCopied = true);

    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  /// Flex shares of the label and the value.
  static const int _labelFlex = 45;
  static const int _valueFlex = 55;

  @override
  Widget build(BuildContext context) {
    // A copyable row keeps the height of the copy button's touch target,
    // so it gets less vertical padding than a plain row.
    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.copyable ? 3 : 13),
      // The label and the value split the row in fixed shares, and the
      // value aligns to the end of its share, so every value and copy
      // button ends at the right edge of the row.
      child: Row(
        children: [
          Expanded(flex: _labelFlex, child: DetailLabel(widget.label)),
          const SizedBox(width: 16),
          Expanded(
            flex: _valueFlex,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                widget.value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: detailValueStyle(context),
              ),
            ),
          ),
          if (widget.copyable) ...[
            const SizedBox(width: 4),
            InlineCopyButton(isCopied: _isCopied, onTap: _copyToClipboard),
          ],
        ],
      ),
    );
  }
}

/// A detail row whose value slot holds an arbitrary trailing widget (a chip, an
/// asset glyph, …) right-aligned against the label.
class DetailTrailingRow extends StatelessWidget {
  final String label;
  final Widget trailing;

  const DetailTrailingRow({
    super.key,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Flexible(flex: 2, child: DetailLabel(label)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}

/// "Asset" row — the asset icon to the left of its name. The asset is its own
/// identifier here, so the row carries no separate text value.
class DetailAssetRow extends StatelessWidget {
  final Asset asset;

  const DetailAssetRow({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return DetailTrailingRow(
      label: AppLocalizations.of(context).wallet_send_conversion_asset,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(asset.iconPath, width: 20, height: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              asset.name,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: detailValueStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label of a detail row.
class DetailLabel extends StatelessWidget {
  final String text;

  const DetailLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colors.textSecondary,
      ),
    );
  }
}

/// Style of the value of a detail row: tabular, so numbers line up.
TextStyle? detailValueStyle(BuildContext context) =>
    context.textTheme.bodyMedium?.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
