import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/utils/formatters.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/bitcoin_price_provider.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/shared/widgets.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  final Map<String, bool> _copiedFields = {};
  int? _currentBlockHeight;

  @override
  void initState() {
    super.initState();
    _fetchCurrentBlockHeight();
  }

  Future<void> _fetchCurrentBlockHeight() async {
    if (widget.transaction.blockchain == Blockchain.bitcoin &&
        widget.transaction.confirmationHeight != null) {
      try {
        final repo = await ref.read(walletRepositoryProvider.future);
        final heightResult = await repo.getCurrentBitcoinBlockHeight();
        heightResult.fold(
          (_) {
            /* repo unavailable — UI falls back to tx-level height */
          },
          (height) {
            if (mounted) {
              setState(() {
                _currentBlockHeight = height;
              });
            }
          },
        );
      } catch (e) {
        // Silently fail
      }
    }
  }

  int? _getConfirmations() {
    if (widget.transaction.confirmationHeight == null ||
        _currentBlockHeight == null) {
      return null;
    }
    return _currentBlockHeight! - widget.transaction.confirmationHeight! + 1;
  }

  @override
  Widget build(BuildContext context) {
    final isReceive = widget.transaction.type == TransactionType.receive;
    final bitcoinPrice = ref.watch(bitcoinPriceProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return PlatformSafeArea(
      child: Scaffold(
        backgroundColor: context.colors.backgroundColor,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            AppLocalizations.of(context).tx_detail_title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTransactionHeader(isReceive, bitcoinPrice, currencySymbol),
              const SizedBox(height: 16),
              _buildDetailsCard(context),
              const SizedBox(height: 16),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Hero card — same _SoftCard / _AssetMedallion / _TickerPill vocabulary
  // as the send-review screen, so the two surfaces read as one system.
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildTransactionHeader(
    bool isReceive,
    AsyncValue<double> bitcoinPrice,
    String currencySymbol,
  ) {
    final isSwap =
        widget.transaction.type == TransactionType.swap ||
        widget.transaction.type == TransactionType.submarine;
    final isRefundableOrFailed =
        widget.transaction.status == TransactionStatus.refundable ||
        widget.transaction.status == TransactionStatus.failed;

    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRefundableOrFailed && _hasSwapDetails())
            _buildRefundableHeader()
          else if (isSwap && _hasSwapDetails())
            _buildSwapHeader()
          else
            _buildRegularHeader(isReceive, bitcoinPrice, currencySymbol),
          const SizedBox(height: 20),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getStatusIcon(), size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                _getStatusLabel(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        if (widget.transaction.status == TransactionStatus.refundable ||
            widget.transaction.status == TransactionStatus.failed) ...[
          const SizedBox(height: 14),
          _buildStatusExplanation(),
        ],
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (widget.transaction.status) {
      case TransactionStatus.pending:
        return Icons.schedule;
      case TransactionStatus.confirmed:
        return Icons.check_circle;
      case TransactionStatus.failed:
        return Icons.check_circle_outline;
      case TransactionStatus.refundable:
        return Icons.warning_amber_rounded;
    }
  }

  Widget _buildStatusExplanation() {
    final t = AppLocalizations.of(context);
    final explanation =
        widget.transaction.status == TransactionStatus.refundable
            ? t.tx_detail_refund_available_msg
            : t.tx_detail_refund_processed_msg;

    return _InfoBanner(
      icon: Icons.info_outline_rounded,
      color: _getStatusColor(),
      message: explanation,
    );
  }

  Widget _buildRegularHeader(
    bool isReceive,
    AsyncValue<double> bitcoinPrice,
    String currencySymbol,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _AssetMedallion(iconPath: widget.transaction.asset.iconPath),
        const SizedBox(height: 14),
        Text(
          widget.transaction.asset.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _getTransactionTypeLabel(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _TickerPill(text: widget.transaction.asset.ticker),
        const SizedBox(height: 16),
        _HeroAmount(
          asset: widget.transaction.asset,
          amountInSats: widget.transaction.amount,
          isReceive: isReceive,
          bitcoinPrice: bitcoinPrice,
          currencySymbol: currencySymbol,
        ),
      ],
    );
  }

  Widget _buildRefundableHeader() {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          widget.transaction.status == TransactionStatus.refundable
              ? t.tx_detail_swap_unfinished
              : t.tx_detail_swap_refunded,
          style: theme.textTheme.labelMedium?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AssetMedallion(
              iconPath: widget.transaction.fromAsset!.iconPath,
              size: 56,
              iconSize: 30,
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.close_rounded,
              size: 22,
              color: context.colors.textTertiary,
            ),
            const SizedBox(width: 16),
            _AssetMedallion(
              iconPath: widget.transaction.toAsset!.iconPath,
              size: 56,
              iconSize: 30,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwapHeader() {
    final theme = Theme.of(context);
    return Column(
      children: [
        _TickerPill(text: AppLocalizations.of(context).tx_detail_swap_label),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Asset FROM
            Expanded(
              child: Column(
                children: [
                  _AssetMedallion(
                    iconPath: widget.transaction.fromAsset!.iconPath,
                    size: 56,
                    iconSize: 30,
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatSwapAmount(
                        widget.transaction.sentAmount!,
                        widget.transaction.fromAsset!,
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            // Asset TO
            Expanded(
              child: Column(
                children: [
                  _AssetMedallion(
                    iconPath: widget.transaction.toAsset!.iconPath,
                    size: 56,
                    iconSize: 30,
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatSwapAmount(
                        widget.transaction.receivedAmount!,
                        widget.transaction.toAsset!,
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.positiveColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _hasSwapDetails() {
    return widget.transaction.fromAsset != null &&
        widget.transaction.toAsset != null &&
        widget.transaction.sentAmount != null &&
        widget.transaction.receivedAmount != null;
  }

  String _formatSwapAmount(BigInt amount, dynamic asset) {
    final formattedAmount = (amount.toDouble() / 100000000).toStringAsFixed(8);
    final cleanAmount = formattedAmount
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    return '$cleanAmount ${asset.ticker}';
  }

  // ─────────────────────────────────────────────────────────────────────
  // Details card — a single _SoftCard with hairline-divided rows, mirroring
  // the send-review _DetailsCard. Info banners (submarine note, confirmation
  // progress, preimage warning) sit in their own padded section at the top.
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDetailsCard(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isSwap = widget.transaction.type == TransactionType.swap;
    final isSubmarineSwap =
        widget.transaction.type == TransactionType.submarine;
    final confirmed = widget.transaction.status == TransactionStatus.confirmed;
    final isRefundableOrFailed =
        widget.transaction.status == TransactionStatus.refundable ||
        widget.transaction.status == TransactionStatus.failed;

    final List<Widget> banners = [];
    final List<Widget> rows = [];

    if (isRefundableOrFailed) {
      rows.add(
        _buildInfoRow(
          icon: Icons.access_time,
          label: t.pix_deposit_date,
          value: _formatDateTime(widget.transaction.createdAt),
        ),
      );
      if (_hasSwapDetails()) {
        rows.add(
          _buildInfoRow(
            icon: Icons.swap_horiz,
            label: t.tx_detail_sent,
            value: widget.transaction.fromAsset!.ticker,
          ),
        );
        rows.add(
          _buildInfoRow(
            icon: Icons.swap_horiz,
            label: t.tx_detail_expected,
            value: widget.transaction.toAsset!.ticker,
          ),
        );
      }
      rows.add(
        _buildInfoRow(
          icon: Icons.link,
          label: t.tx_detail_blockchain,
          value: _getBlockchainLabel(),
        ),
      );
      // Refunded peg (`{sendId}_{receiveId}_refund` synthetic id, NOT a chain
      // txid) → render the two real txids separately instead of leaking the
      // synthetic id to the user as if it were valid.
      if (_isRefundedSwap()) {
        rows.addAll(_buildRefundedSwapIds());
      } else if (widget.transaction.id.isNotEmpty) {
        rows.add(
          _buildInfoRow(
            icon: Icons.tag,
            label: t.tx_id,
            value: truncateHashId(widget.transaction.id),
            copyable: true,
            copyFieldId: 'transaction_id',
            copyValue: widget.transaction.id,
          ),
        );
      }
    } else {
      if (isSubmarineSwap && !confirmed) {
        banners.add(_buildSubmarineSwapExplanation());
      }

      if (widget.transaction.blockchain == Blockchain.bitcoin &&
          widget.transaction.status != TransactionStatus.confirmed) {
        banners.add(_buildConfirmationRow());
      }

      rows.add(
        _buildInfoRow(
          icon: Icons.access_time,
          label: t.pix_deposit_date,
          value: _formatDateTime(widget.transaction.createdAt),
        ),
      );

      if (!(isSwap && _hasSwapDetails())) {
        rows.add(
          _buildInfoRow(
            icon: Icons.monetization_on,
            label: t.tx_filter_currency,
            value: widget.transaction.asset.name,
          ),
        );
        rows.add(
          _buildInfoRow(
            icon: Icons.account_balance_wallet,
            label: t.wallet_amount,
            value:
                '${(widget.transaction.amount.toDouble() / 100000000).toStringAsFixed(8)} ${widget.transaction.asset.ticker}',
          ),
        );
      }

      rows.add(
        _buildInfoRow(
          icon: Icons.link,
          label: t.tx_detail_blockchain,
          value: _getBlockchainLabel(),
        ),
      );

      if (isSwap && _isCrossChainSwap()) {
        rows.addAll(_buildCrossChainSwapIds());
      } else if (isSwap && _isRefundedSwap()) {
        rows.addAll(_buildRefundedSwapIds());
      } else {
        rows.add(
          _buildInfoRow(
            icon: Icons.tag,
            label: t.tx_id,
            value: truncateHashId(widget.transaction.id),
            copyable: true,
            copyFieldId: 'transaction_id',
            copyValue: widget.transaction.id,
          ),
        );
      }

      if (widget.transaction.blockchain == Blockchain.lightning) {
        if (widget.transaction.destination != null) {
          rows.add(
            _buildInfoRow(
              icon: Icons.qr_code,
              label:
                  widget.transaction.type == TransactionType.send
                      ? "LNURL"
                      : "Invoice",
              value: truncateHashId(widget.transaction.destination!),
              copyable: true,
              copyFieldId: 'destination',
              copyValue: widget.transaction.destination!,
            ),
          );
        }
        if (widget.transaction.preimage != null) {
          rows.add(
            _buildInfoRow(
              icon: Icons.key,
              label: t.tx_detail_preimage_label,
              value: truncateHashId(widget.transaction.preimage!),
              copyable: true,
              copyFieldId: 'preimagem',
              copyValue: widget.transaction.preimage!,
            ),
          );
        } else if (widget.transaction.status == TransactionStatus.pending) {
          banners.add(_buildPreimageWarning());
        }
      }
    }

    return _SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, banners.isEmpty ? 6 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.pix_deposit_info,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                for (final banner in banners) ...[
                  const SizedBox(height: 12),
                  banner,
                ],
              ],
            ),
          ),
          ..._withDividers(rows),
        ],
      ),
    );
  }

  /// Inserts hairline dividers between every detail row so the card reads as
  /// one continuous list rather than a stack of boxed items.
  List<Widget> _withDividers(List<Widget> rows) {
    final theme = Theme.of(context);
    final dividerColor =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
            : theme.colorScheme.onSurface.withValues(alpha: 0.05);

    final result = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      result.add(Divider(height: 1, thickness: 1, color: dividerColor));
      result.add(rows[i]);
    }
    return result;
  }

  Widget _buildSubmarineSwapExplanation() {
    final t = AppLocalizations.of(context);
    final fromAsset = widget.transaction.fromAsset;
    final toAsset = widget.transaction.toAsset;

    String explanation;
    if (fromAsset != null && toAsset != null) {
      if (fromAsset == Asset.btc && toAsset == Asset.lbtc) {
        explanation = t.tx_detail_submarine_btc_to_lbtc(
          fromAsset.ticker,
          toAsset.ticker,
        );
      } else if (fromAsset == Asset.lbtc && toAsset == Asset.btc) {
        explanation = t.tx_detail_submarine_lbtc_to_btc(
          fromAsset.ticker,
          toAsset.ticker,
        );
      } else {
        explanation = t.tx_detail_submarine_generic;
      }
    } else {
      explanation = t.tx_detail_submarine_default;
    }

    return _InfoBanner(
      icon: Icons.info_outline_rounded,
      color: Theme.of(context).colorScheme.primary,
      message: explanation,
    );
  }

  Widget _buildPreimageWarning() {
    return _InfoBanner(
      icon: Icons.schedule,
      color: context.appColors.warning,
      message: AppLocalizations.of(context).tx_detail_preimage_pending,
    );
  }

  Widget _buildConfirmationRow() {
    final t = AppLocalizations.of(context);
    final confirmations = _getConfirmations();
    final isFullyConfirmed = confirmations != null && confirmations >= 6;

    String displayText;
    Color displayColor;

    if (confirmations == null) {
      displayText = t.common_verifying;
      displayColor = Theme.of(context).colorScheme.outline;
    } else if (confirmations >= 6) {
      displayText = t.tx_detail_confirmations_full;
      displayColor = context.colors.positiveColor;
    } else {
      displayText = t.tx_detail_confirmations_progress(confirmations);
      displayColor = context.appColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: displayColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: displayColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isFullyConfirmed ? Icons.check_circle : Icons.schedule,
              size: 18,
              color: displayColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).tx_detail_confirmations,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayText,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: displayColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool copyable = false,
    String? copyFieldId,
    String? copyValue,
  }) {
    final theme = Theme.of(context);
    final fieldId = copyFieldId ?? label;
    final isCopied = _copiedFields[fieldId] ?? false;
    final valueToCopy = copyValue ?? value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 13, 14, 13),
      child: Row(
        children: [
          Icon(icon, size: 17, color: context.colors.textTertiary),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (copyable) ...[
            const SizedBox(width: 6),
            _InlineCopyButton(
              isCopied: isCopied,
              onTap: () => _copyToClipboard(valueToCopy, fieldId),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Action buttons — soft list-tile vocabulary matching the rest of the
  // screen. Disabled buttons dim, enabled ones ripple.
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isRefundable =
        widget.transaction.status == TransactionStatus.refundable;

    if (isRefundable) {
      return _buildActionButton(
        context: context,
        label: t.tx_detail_request_refund,
        subtitle: t.tx_detail_request_refund_subtitle,
        icon: Icons.refresh,
        onPressed: () {
          context.push('/transactions/refund', extra: widget.transaction);
        },
        isPrimary: true,
      );
    }

    if (_isCrossChainSwap()) {
      final sendEnabled = _isExplorerEnabledFor(
        txId: widget.transaction.sendTxId,
        blockchain: widget.transaction.sendBlockchain,
      );
      final receiveEnabled = _isExplorerEnabledFor(
        txId: widget.transaction.receiveTxId,
        blockchain: widget.transaction.receiveBlockchain,
      );
      return Column(
        children: [
          _buildActionButton(
            context: context,
            label: t.tx_detail_view_send,
            subtitle: _getBlockchainName(widget.transaction.sendBlockchain!),
            icon: Icons.call_made,
            onPressed:
                sendEnabled
                    ? () => _openInExplorer(
                      txId: widget.transaction.sendTxId,
                      blockchain: widget.transaction.sendBlockchain,
                    )
                    : null,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context: context,
            label: t.tx_detail_view_receive,
            subtitle: _getBlockchainName(widget.transaction.receiveBlockchain!),
            icon: Icons.call_received,
            onPressed:
                receiveEnabled
                    ? () => _openInExplorer(
                      txId: widget.transaction.receiveTxId,
                      blockchain: widget.transaction.receiveBlockchain,
                    )
                    : null,
          ),
        ],
      );
    }

    // Refunded peg: same chain on both sides but two distinct txids.
    // The default branch below would try to open the synthetic
    // `{send}_{receive}_refund` id in a block explorer and 404 — give
    // the user one button per real txid instead.
    if (_isRefundedSwap()) {
      final chainName =
          widget.transaction.sendBlockchain == null
              ? ''
              : _getBlockchainName(widget.transaction.sendBlockchain!);
      final sendEnabled = _isExplorerEnabledFor(
        txId: widget.transaction.sendTxId,
        blockchain: widget.transaction.sendBlockchain,
      );
      final refundEnabled = _isExplorerEnabledFor(
        txId: widget.transaction.receiveTxId,
        blockchain: widget.transaction.receiveBlockchain,
      );
      return Column(
        children: [
          _buildActionButton(
            context: context,
            label: 'View send transaction',
            subtitle: chainName,
            icon: Icons.call_made,
            onPressed:
                sendEnabled
                    ? () => _openInExplorer(
                      txId: widget.transaction.sendTxId,
                      blockchain: widget.transaction.sendBlockchain,
                    )
                    : null,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context: context,
            label: 'View refund transaction',
            subtitle: chainName,
            icon: Icons.assignment_return,
            onPressed:
                refundEnabled
                    ? () => _openInExplorer(
                      txId: widget.transaction.receiveTxId,
                      blockchain: widget.transaction.receiveBlockchain,
                    )
                    : null,
          ),
        ],
      );
    }

    final defaultExplorerEnabled = _isExplorerEnabledFor();
    return Column(
      children: [
        _buildActionButton(
          context: context,
          label: t.pix_deposit_view_explorer,
          subtitle: t.pix_deposit_view_chain,
          icon: Icons.open_in_new,
          onPressed: defaultExplorerEnabled ? () => _openInExplorer() : null,
        ),
        if (widget.transaction.blockchain == Blockchain.lightning &&
            widget.transaction.destination != null &&
            widget.transaction.preimage != null) ...[
          const SizedBox(height: 12),
          _buildActionButton(
            context: context,
            label: t.tx_detail_validate_payment,
            subtitle: t.tx_detail_verify_preimage,
            icon: Icons.verified,
            onPressed: () => _openValidationUrl(),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final enabled = onPressed != null;
    final accent = cs.primary;

    final body = _SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isPrimary ? accent : accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isPrimary ? cs.onPrimary : accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: context.colors.textTertiary,
          ),
        ],
      ),
    );

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child:
          enabled
              ? Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(onTap: onPressed, child: body),
              )
              : body,
    );
  }

  String _getTransactionTypeLabel() {
    final t = AppLocalizations.of(context);
    switch (widget.transaction.type) {
      case TransactionType.send:
        return t.tx_type_send;
      case TransactionType.receive:
        return t.tx_type_receive;
      case TransactionType.swap:
        return t.tx_type_swap;
      case TransactionType.redeposit:
        return t.tx_type_redeposit;
      case TransactionType.submarine:
        return t.tx_type_swap;
      case TransactionType.unknown:
        return t.tx_type_unknown;
    }
  }

  String _getStatusLabel() {
    final t = AppLocalizations.of(context);
    switch (widget.transaction.status) {
      case TransactionStatus.pending:
        return t.tx_status_pending;
      case TransactionStatus.confirmed:
        return t.tx_status_confirmed_fem;
      case TransactionStatus.failed:
        return t.tx_status_failed_processed;
      case TransactionStatus.refundable:
        return t.tx_status_refundable_pending;
    }
  }

  String _getBlockchainLabel() {
    switch (widget.transaction.blockchain) {
      case Blockchain.bitcoin:
        return 'Bitcoin';
      case Blockchain.lightning:
        return 'Lightning Network';
      case Blockchain.liquid:
        return 'Liquid Network';
    }
  }

  Color _getStatusColor() {
    final colors = context.colors;
    final appColors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.transaction.type == TransactionType.swap &&
        widget.transaction.status == TransactionStatus.confirmed) {
      return colors.positiveColor;
    }

    switch (widget.transaction.status) {
      case TransactionStatus.pending:
        return appColors.warning;
      case TransactionStatus.confirmed:
        return colors.positiveColor;
      case TransactionStatus.failed:
        return colorScheme.error;
      case TransactionStatus.refundable:
        return colorScheme.primary;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    return formatter.format(dateTime);
  }

  void _copyToClipboard(String text, String fieldId) {
    Clipboard.setData(ClipboardData(text: text));

    setState(() {
      _copiedFields[fieldId] = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedFields[fieldId] = false;
        });
      }
    });
  }

  String _urlFor(String txId, Blockchain blockchain) {
    return switch (blockchain) {
      Blockchain.bitcoin => 'https://mempool.bitaroo.net/pt/tx/$txId',
      Blockchain.liquid => 'https://liquid.network/pt/tx/$txId',
      Blockchain.lightning => 'https://blockstream.info/liquid/tx/$txId',
    };
  }

  Blockchain _effectiveExplorerBlockchain() {
    final tx = widget.transaction;
    if (tx.type == TransactionType.submarine) {
      return Blockchain.liquid;
    }
    final sendChain = tx.sendBlockchain;
    final receiveChain = tx.receiveBlockchain;
    if (sendChain != null &&
        receiveChain != null &&
        sendChain != receiveChain) {
      if (tx.receiveTxId != null && tx.id == tx.receiveTxId) {
        return receiveChain;
      }
      if (tx.sendTxId != null && tx.id == tx.sendTxId) {
        return sendChain;
      }
      // Id doesn't match either leg: during pending peg-out the
      // lockup is the only on-chain tx, so prefer the send chain.
      return sendChain;
    }
    return tx.blockchain;
  }

  String? _resolveExplorerUrl({String? txId, Blockchain? blockchain}) {
    if (blockchain != null && txId == null) return null;
    final useTxId = txId ?? widget.transaction.id;
    if (useTxId.isEmpty) return null;
    final useBlockchain = blockchain ?? _effectiveExplorerBlockchain();
    return _urlFor(useTxId, useBlockchain);
  }

  static final RegExp _finalTxIdRegex = RegExp(r'^[0-9a-fA-F]{64}$');

  bool _isFinalTxId(String? value) {
    if (value == null || value.isEmpty) return false;
    return _finalTxIdRegex.hasMatch(value);
  }

  bool _isExplorerEnabledFor({String? txId, Blockchain? blockchain}) {
    final url = _resolveExplorerUrl(txId: txId, blockchain: blockchain);
    if (url == null) return false;
    final match = RegExp(r'/tx/([^/?#]+)').firstMatch(url);
    return _isFinalTxId(match?.group(1));
  }

  Future<void> _openInExplorer({String? txId, Blockchain? blockchain}) async {
    final explorerUrl = _resolveExplorerUrl(txId: txId, blockchain: blockchain);
    if (explorerUrl == null) return;

    final Uri url = Uri.parse(explorerUrl);

    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        await Clipboard.setData(ClipboardData(text: explorerUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).error_open_browser_link_copied,
            ),
            backgroundColor: context.appColors.warning,
          ),
        );
      }
    }
  }

  Future<void> _openValidationUrl() async {
    if (widget.transaction.destination == null ||
        widget.transaction.preimage == null) {
      return;
    }

    final validationUrl =
        'https://validate-payment.com/?invoice=${widget.transaction.destination!}&preimage=${widget.transaction.preimage!}';

    final Uri url = Uri.parse(validationUrl);

    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        await Clipboard.setData(ClipboardData(text: validationUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).error_open_browser_link_copied,
            ),
            backgroundColor: context.appColors.warning,
          ),
        );
      }
    }
  }

  bool _isCrossChainSwap() {
    final tx = widget.transaction;
    if (tx.sendBlockchain == null || tx.receiveBlockchain == null) return false;
    if (tx.sendBlockchain == tx.receiveBlockchain) return false;
    return tx.sendTxId != null || tx.receiveTxId != null;
  }

  /// Refunded-peg attempt as produced by `swap_unifier.dart`:
  bool _isRefundedSwap() {
    final tx = widget.transaction;
    if (tx.type != TransactionType.swap) return false;
    if (tx.fromAsset == null || tx.fromAsset != tx.toAsset) return false;
    if (tx.fromAsset != Asset.btc) return false;
    if (tx.sendBlockchain != null && tx.sendBlockchain != Blockchain.bitcoin) {
      return false;
    }
    if (tx.receiveBlockchain != null &&
        tx.receiveBlockchain != Blockchain.bitcoin) {
      return false;
    }
    return tx.sendTxId != null && tx.receiveTxId != null;
  }

  List<Widget> _buildCrossChainSwapIds() {
    final t = AppLocalizations.of(context);

    final sendTxId = widget.transaction.sendTxId;
    final receiveTxId = widget.transaction.receiveTxId;
    return [
      _buildInfoRow(
        icon: Icons.call_made,
        label: t.tx_detail_send_id_label(
          _getBlockchainName(widget.transaction.sendBlockchain!),
        ),
        value: sendTxId == null ? '—' : truncateHashId(sendTxId),
        copyable: sendTxId != null,
        copyFieldId: 'send_tx_id',
        copyValue: sendTxId ?? '',
      ),
      _buildInfoRow(
        icon: Icons.call_received,
        label: t.tx_detail_receive_id_label(
          _getBlockchainName(widget.transaction.receiveBlockchain!),
        ),
        value: receiveTxId == null ? '—' : truncateHashId(receiveTxId),
        copyable: receiveTxId != null,
        copyFieldId: 'receive_tx_id',
        copyValue: receiveTxId ?? '',
      ),
    ];
  }

  /// Refund-specific dual id rendering. Labels lean on the
  /// existing send/receive l10n keys but explicitly mention "refund"
  /// in the receive slot so the user understands the second tx is
  /// not the swap's destination credit, it's the funds coming back.
  List<Widget> _buildRefundedSwapIds() {
    final chainSuffix =
        widget.transaction.sendBlockchain == null
            ? ''
            : ' (${_getBlockchainName(widget.transaction.sendBlockchain!)})';
    return [
      _buildInfoRow(
        icon: Icons.call_made,
        label: 'Send TX ID$chainSuffix',
        value: truncateHashId(widget.transaction.sendTxId!),
        copyable: true,
        copyFieldId: 'send_tx_id',
        copyValue: widget.transaction.sendTxId!,
      ),
      _buildInfoRow(
        icon: Icons.assignment_return,
        label: 'Refund TX ID$chainSuffix',
        value: truncateHashId(widget.transaction.receiveTxId!),
        copyable: true,
        copyFieldId: 'refund_tx_id',
        copyValue: widget.transaction.receiveTxId!,
      ),
    ];
  }

  String _getBlockchainName(Blockchain blockchain) {
    switch (blockchain) {
      case Blockchain.bitcoin:
        return 'Bitcoin';
      case Blockchain.liquid:
        return 'Liquid';
      case Blockchain.lightning:
        return 'Lightning';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared visual vocabulary — mirrors the send-review screen so transaction
// detail and review feel like one cohesive design system.
// ─────────────────────────────────────────────────────────────────────────

/// Soft elevated surface — Coinbase / Cash App vocabulary.
///   • light mode → very subtle drop shadow over a surface fill
///   • dark mode  → a slightly elevated container tier + ultra-thin hairline
class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : cs.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            isDark
                ? Border.all(color: cs.onSurface.withValues(alpha: 0.06))
                : null,
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
      ),
      child: child,
    );
  }
}

/// Circular asset badge with a soft elevation, used as the focal point of the
/// hero card.
class _AssetMedallion extends StatelessWidget {
  final String iconPath;
  final double size;
  final double iconSize;

  const _AssetMedallion({
    required this.iconPath,
    this.size = 64,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? cs.surfaceContainerHighest : cs.surface,
        border:
            isDark
                ? Border.all(color: cs.onSurface.withValues(alpha: 0.06))
                : null,
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        iconPath,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Small primary-tinted pill — ticker or short label under the medallion.
class _TickerPill extends StatelessWidget {
  final String text;
  const _TickerPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Hero amount stack — sats are the principal figure for BTC-like assets
/// (with the BTC decimal and a fiat line underneath); token assets keep their
/// native decimal amount. Mirrors the send-review `_HeroAmountStack`, but adds
/// the receive `+` sign and positive tint so credits read at a glance.
class _HeroAmount extends StatelessWidget {
  final Asset asset;
  final BigInt amountInSats;
  final bool isReceive;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _HeroAmount({
    required this.asset,
    required this.amountInSats,
    required this.isReceive,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBtcLike = asset == Asset.btc || asset == Asset.lbtc;
    final sign = isReceive ? '+' : '';
    final amountColor =
        isReceive ? context.colors.positiveColor : theme.colorScheme.onSurface;

    final amount = amountInSats.toDouble() / 100000000;
    final decimalStr =
        isBtcLike
            ? amount.toStringAsFixed(8)
            : amount
                .toStringAsFixed(8)
                .replaceAll(RegExp(r'0+$'), '')
                .replaceAll(RegExp(r'\.$'), '');

    final principal =
        isBtcLike
            ? '$sign${SatsInputFormatter.formatValue(amountInSats.toInt())} sats'
            : '$sign$decimalStr ${asset.ticker}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            principal,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: amountColor,
              letterSpacing: -0.6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (isBtcLike) ...[
          const SizedBox(height: 8),
          Text(
            '$sign$decimalStr ${asset.ticker}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          _HeroFiatLine(
            amountInSats: amountInSats,
            bitcoinPrice: bitcoinPrice,
            currencySymbol: currencySymbol,
          ),
        ],
      ],
    );
  }
}

/// Fiat conversion line for the hero amount — only meaningful for BTC-priced
/// amounts, so the parent gates it to BTC-like assets. Values are formatted
/// against the active app locale so thousands grouping and the decimal
/// separator follow the user's regional conventions (en_US `4,999.11`,
/// pt_BR / es_ES `4.999,11`).
class _HeroFiatLine extends ConsumerWidget {
  final BigInt amountInSats;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _HeroFiatLine({
    required this.amountInSats,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,##0.00', ref.watch(localeStringProvider));
    final style = theme.textTheme.titleSmall?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return bitcoinPrice.when(
      data: (price) {
        if (price <= 0) return const SizedBox.shrink();
        final fiat = (amountInSats.toDouble() / 100000000) * price;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$currencySymbol ${formatter.format(fiat)}',
            style: style,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Tinted informational banner — submarine notes, refund explanations and
/// pending-preimage warnings all share this recipe so they read consistently.
class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact animated copy affordance shared by every copyable detail row.
class _InlineCopyButton extends StatelessWidget {
  final bool isCopied;
  final VoidCallback onTap;

  const _InlineCopyButton({required this.isCopied, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final positive = context.colors.positiveColor;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: SizedBox(
            key: ValueKey(isCopied),
            width: 30,
            height: 30,
            child: Icon(
              isCopied ? Icons.check_rounded : Icons.copy_rounded,
              size: 16,
              color: isCopied ? positive : cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
