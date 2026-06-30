import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/utils/formatters.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/bitcoin_price_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:mooze_mobile/features/swap/presentation/widgets/swap_deal_card.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/transaction_indicator_badge.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/confirmation_banner.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail_row.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/hero_amount.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/in_card_action_button.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/info_banner.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/soft_card.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/swap_status_badge.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/utils/transaction_display_x.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/utils/transaction_fee_x.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
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
    final currencySymbol = ref.watch(currencySymbolProvider);
    final isSendOrReceive =
        widget.transaction.type == TransactionType.send ||
        widget.transaction.type == TransactionType.receive;

    return PlatformSafeArea(
      child: Scaffold(
        backgroundColor: context.colors.backgroundColor,
        appBar: AppBar(
          elevation: 0,
          title: Text(AppLocalizations.of(context).tx_detail_title),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTransactionHeader(isReceive, currencySymbol),
              const SizedBox(height: 16),
              if (isSendOrReceive)
                _buildSendReceiveCard(context)
              else
                _buildDetailsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Header — a tinted directional medallion for send/receive, and the shared
  // [SwapDealCard] for swap/refund so every surface reads as one system.
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildTransactionHeader(bool isReceive, String currencySymbol) {
    final isSwap =
        widget.transaction.type == TransactionType.swap ||
        widget.transaction.type == TransactionType.submarine;
    final isRefundableOrFailed =
        widget.transaction.status == TransactionStatus.refundable ||
        widget.transaction.status == TransactionStatus.failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRefundableOrFailed && _hasSwapDetails())
          _buildRefundableHeader()
        else if (isSwap && _hasSwapDetails())
          _buildSwapHeader()
        else
          _buildRegularHeader(isReceive, currencySymbol),
      ],
    );
  }

  Widget _buildRegularHeader(bool isReceive, String currencySymbol) {
    final theme = Theme.of(context);
    final tx = widget.transaction;
    final colors = context.colors;

    return Column(
      children: [
        TransactionIndicatorBadge.direction(
          context: context,
          isReceive: isReceive,
        ),
        const SizedBox(height: 14),
        Text(
          tx.type.label(AppLocalizations.of(context)),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isReceive ? colors.positiveColor : colors.negativeColor,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 20),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeroAmount(
                asset: tx.asset,
                amountInSats: tx.amount,
                isReceive: isReceive,
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: _heroDividerColor(theme)),
              const SizedBox(height: 14),
              HeroAssetRow(asset: tx.asset),
            ],
          ),
        ),
      ],
    );
  }

  Color _heroDividerColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? theme.colorScheme.outlineVariant.withValues(alpha: 0.35)
          : theme.colorScheme.outline.withValues(alpha: 0.45);

  Widget _buildSendReceiveCard(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    final isLightning = tx.blockchain == Blockchain.lightning;

    final banners = <Widget>[];
    final rows = <Widget>[];

    if (tx.blockchain == Blockchain.bitcoin &&
        tx.status != TransactionStatus.confirmed) {
      banners.add(ConfirmationBanner(confirmations: _getConfirmations()));
    }

    rows.add(_buildStatusRow());
    rows.add(
      DetailRow(
        label: t.pix_deposit_date,
        value: _formatLocalizedDateTime(tx.createdAt),
      ),
    );
    rows.add(DetailAssetRow(asset: tx.asset));
    rows.add(
      DetailRow(
        label: t.wallet_amount,
        value:
            '${(tx.amount.toDouble() / 100000000).toStringAsFixed(8)} ${tx.asset.ticker}',
      ),
    );
    rows.add(
      DetailRow(
        label: t.tx_detail_blockchain,
        value: tx.blockchain.networkLabel,
      ),
    );

    _addFeeRow(rows, t);

    if (tx.id.isNotEmpty) {
      rows.add(
        DetailRow(
          label: t.tx_id,
          value: truncateHashId(tx.id),
          copyable: true,
          copyValue: tx.id,
        ),
      );
    }

    if (isLightning) {
      if (tx.destination != null) {
        rows.add(
          DetailRow(
            label: tx.type == TransactionType.send ? 'LNURL' : 'Invoice',
            value: truncateHashId(tx.destination!),
            copyable: true,
            copyValue: tx.destination!,
          ),
        );
      }
      if (tx.preimage != null) {
        rows.add(
          DetailRow(
            label: t.tx_detail_preimage_label,
            value: truncateHashId(tx.preimage!),
            copyable: true,
            copyValue: tx.preimage!,
          ),
        );
      } else if (tx.status == TransactionStatus.pending) {
        banners.add(_buildPreimageWarning());
      }
    }

    final actions = _buildSendReceiveActions(context);

    return _assembleCard(banners: banners, rows: rows, actions: actions);
  }

  Widget _assembleCard({
    required List<Widget> banners,
    required List<Widget> rows,
    required List<Widget> actions,
  }) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (banners.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (var i = 0; i < banners.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              banners[i],
            ],
            const SizedBox(height: 4),
          ],
          for (final row in rows) row,
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              actions[i],
            ],
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  void _addFeeRow(List<Widget> rows, AppLocalizations t) {
    final feeSat = widget.transaction.totalFeeSat;
    if (feeSat == null) return;
    rows.add(
      DetailRow(label: t.tx_detail_fee, value: _formatFeeSats(feeSat)),
    );
  }

  String _formatFeeSats(BigInt feeSat) {
    final unit = feeSat == BigInt.one ? 'sat' : 'sats';
    return '${SatsInputFormatter.formatValue(feeSat.toInt())} $unit';
  }

  Widget _buildStatusRow() {
    final tx = widget.transaction;
    return DetailTrailingRow(
      label: AppLocalizations.of(context).tx_filter_status,
      trailing: StatusChip(
        icon: tx.status.icon,
        label: tx.status.label(AppLocalizations.of(context)),
        color: tx.statusColor(context),
      ),
    );
  }

  List<Widget> _buildSendReceiveActions(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    final actions = <Widget>[];

    actions.add(
      InCardActionButton(
        label: t.pix_deposit_view_explorer,
        subtitle: t.pix_deposit_view_chain,
        icon: Icons.open_in_new,
        onPressed: _isExplorerEnabledFor() ? () => _openInExplorer() : null,
      ),
    );

    if (tx.blockchain == Blockchain.lightning &&
        tx.destination != null &&
        tx.preimage != null) {
      actions.add(
        InCardActionButton(
          label: t.tx_detail_validate_payment,
          subtitle: t.tx_detail_verify_preimage,
          icon: Icons.verified,
          onPressed: () => _openValidationUrl(),
        ),
      );
    }
    return actions;
  }

  String _formatLocalizedDateTime(DateTime dateTime) {
    final locale = ref.read(localeStringProvider);
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final datePart = DateFormat.yMMMMd(locale).format(dateTime);
    final timePart = (use24h ? DateFormat.Hm(locale) : DateFormat.jm(locale))
        .format(dateTime);
    return AppLocalizations.of(context).tx_detail_datetime(datePart, timePart);
  }

  Widget _buildRefundableHeader() {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    return Column(
      children: [
        _buildSwapStatusBadge(),
        const SizedBox(height: 16),
        SwapDealCard(
          sendAsset: tx.fromAsset!,
          sendAmountSats: tx.sentAmount!.toInt(),
          receiveAsset: tx.toAsset!,
          receiveAmountSats: tx.receivedAmount!.toInt(),
          sendLabel: t.tx_detail_sent,
          receiveLabel: t.tx_detail_expected,
          sendFiat: _fiatEstimateFor(tx.fromAsset!, tx.sentAmount!),
          receiveFiat: _fiatEstimateFor(tx.toAsset!, tx.receivedAmount!),
          backgroundColor:
              isDark
                  ? cs.onSurface.withValues(alpha: 0.05)
                  : cs.surfaceContainerHighest,
          borderColor:
              isDark
                  ? cs.onSurface.withValues(alpha: 0.08)
                  : cs.outline.withValues(alpha: 0.55),
        ),
      ],
    );
  }

  Widget _buildSwapHeader() {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    return Column(
      children: [
        _buildSwapStatusBadge(),
        const SizedBox(height: 16),
        SwapDealCard(
          sendAsset: tx.fromAsset!,
          sendAmountSats: tx.sentAmount!.toInt(),
          receiveAsset: tx.toAsset!,
          receiveAmountSats: tx.receivedAmount!.toInt(),
          sendLabel: t.tx_detail_sent,
          receiveLabel: t.tx_detail_received,
          sendFiat: _fiatEstimateFor(tx.fromAsset!, tx.sentAmount!),
          receiveFiat: _fiatEstimateFor(tx.toAsset!, tx.receivedAmount!),
          backgroundColor:
              isDark
                  ? cs.onSurface.withValues(alpha: 0.05)
                  : cs.surfaceContainerHighest,
          borderColor:
              isDark
                  ? cs.onSurface.withValues(alpha: 0.08)
                  : cs.outline.withValues(alpha: 0.55),
        ),
      ],
    );
  }

  Widget _buildSwapStatusBadge() {
    final tx = widget.transaction;
    return SwapStatusBadge(
      icon: tx.status.swapIcon,
      label: tx.status.swapLabel(AppLocalizations.of(context)),
      color: tx.statusColor(context),
    );
  }

  bool _hasSwapDetails() {
    return widget.transaction.fromAsset != null &&
        widget.transaction.toAsset != null &&
        widget.transaction.sentAmount != null &&
        widget.transaction.receivedAmount != null;
  }

  String? _fiatEstimateFor(Asset asset, BigInt amount) {
    
    final price = ref.watch(
      priceQuotesProvider.select((quotes) => quotes.priceFor(asset)),
    );
    if (price == null || price <= 0) return null;
    final symbol = ref.watch(currencySymbolProvider);
    final formatter = NumberFormat('#,##0.00', ref.watch(localeStringProvider));
    return '$symbol ${formatter.format(asset.toUsd(amount, price))}';
  }

  // ─────────────────────────────────────────────────────────────────────
  // Swap / refund details card — shares the exact layout vocabulary as the
  // send/receive card (no title, no row icons, no dividers, copy-where-it-
  // matters, actions folded in) so both surfaces read as one system.
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDetailsCard(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    final isSwap = tx.type == TransactionType.swap;
    final isSubmarineSwap = tx.type == TransactionType.submarine;
    final confirmed = tx.status == TransactionStatus.confirmed;
    final isRefundableOrFailed =
        tx.status == TransactionStatus.refundable ||
        tx.status == TransactionStatus.failed;

    final List<Widget> banners = [];
    final List<Widget> rows = [];

    if (isRefundableOrFailed) {
      rows.add(_buildStatusRow());
      rows.add(
        DetailRow(
          label: t.pix_deposit_date,
          value: _formatLocalizedDateTime(tx.createdAt),
        ),
      );
      if (_hasSwapDetails()) {
        rows.add(DetailRow(label: t.tx_detail_sent, value: tx.fromAsset!.ticker));
        rows.add(
          DetailRow(label: t.tx_detail_expected, value: tx.toAsset!.ticker),
        );
      }
      rows.add(
        DetailRow(
        label: t.tx_detail_blockchain,
        value: tx.blockchain.networkLabel,
      ),
      );
      _addFeeRow(rows, t);
      // Refunded peg (`{sendId}_{receiveId}_refund` synthetic id, NOT a chain
      // txid) → render the two real txids separately instead of leaking the
      // synthetic id to the user as if it were valid.
      if (_isRefundedSwap()) {
        rows.addAll(_buildRefundedSwapIds());
      } else if (tx.id.isNotEmpty) {
        rows.add(
          DetailRow(
            label: t.tx_id,
            value: truncateHashId(tx.id),
            copyable: true,
            copyValue: tx.id,
          ),
        );
      }
    } else {
      if (isSubmarineSwap && !confirmed) {
        banners.add(_buildSubmarineSwapExplanation());
      }

      if (tx.blockchain == Blockchain.bitcoin &&
          tx.status != TransactionStatus.confirmed) {
        banners.add(ConfirmationBanner(confirmations: _getConfirmations()));
      }

      rows.add(_buildStatusRow());
      rows.add(
        DetailRow(
          label: t.pix_deposit_date,
          value: _formatLocalizedDateTime(tx.createdAt),
        ),
      );

      if (!(isSwap && _hasSwapDetails())) {
        rows.add(DetailRow(label: t.tx_filter_currency, value: tx.asset.name));
        rows.add(
          DetailRow(
            label: t.wallet_amount,
            value:
                '${(tx.amount.toDouble() / 100000000).toStringAsFixed(8)} ${tx.asset.ticker}',
          ),
        );
      }

      rows.add(
        DetailRow(
        label: t.tx_detail_blockchain,
        value: tx.blockchain.networkLabel,
      ),
      );

      _addFeeRow(rows, t);

      if (isSwap && _isCrossChainSwap()) {
        rows.addAll(_buildCrossChainSwapIds());
      } else if (isSwap && _isRefundedSwap()) {
        rows.addAll(_buildRefundedSwapIds());
      } else {
        rows.add(
          DetailRow(
            label: t.tx_id,
            value: truncateHashId(tx.id),
            copyable: true,
            copyValue: tx.id,
          ),
        );
      }

      if (tx.blockchain == Blockchain.lightning) {
        if (tx.destination != null) {
          rows.add(
            DetailRow(
              label: tx.type == TransactionType.send ? "LNURL" : "Invoice",
              value: truncateHashId(tx.destination!),
              copyable: true,
              copyValue: tx.destination!,
            ),
          );
        }
        if (tx.preimage != null) {
          rows.add(
            DetailRow(
              label: t.tx_detail_preimage_label,
              value: truncateHashId(tx.preimage!),
              copyable: true,
              copyValue: tx.preimage!,
            ),
          );
        } else if (tx.status == TransactionStatus.pending) {
          banners.add(_buildPreimageWarning());
        }
      }
    }

    return _assembleCard(
      banners: banners,
      rows: rows,
      actions: _buildSwapActions(context),
    );
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

    return InfoBanner(
      icon: Icons.info_outline_rounded,
      color: Theme.of(context).colorScheme.primary,
      message: explanation,
    );
  }

  Widget _buildPreimageWarning() {
    return InfoBanner(
      icon: Icons.schedule,
      color: context.appColors.warning,
      message: AppLocalizations.of(context).tx_detail_preimage_pending,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Action buttons — soft list-tile vocabulary matching the rest of the
  // screen. Disabled buttons dim, enabled ones ripple.
  // ─────────────────────────────────────────────────────────────────────

  /// Action buttons for the swap/refund card, rendered with the same in-card
  /// vocabulary as the send/receive card so every CTA on the screen matches.
  List<Widget> _buildSwapActions(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    final isRefundable = tx.status == TransactionStatus.refundable;

    if (isRefundable) {
      return [
        InCardActionButton(
          label: t.tx_detail_request_refund,
          subtitle: t.tx_detail_request_refund_subtitle,
          icon: Icons.refresh,
          onPressed: () {
            context.push('/transactions/refund', extra: tx);
          },
          isPrimary: true,
        ),
      ];
    }

    if (_isCrossChainSwap()) {
      final sendEnabled = _isExplorerEnabledFor(
        txId: tx.sendTxId,
        blockchain: tx.sendBlockchain,
      );
      final receiveEnabled = _isExplorerEnabledFor(
        txId: tx.receiveTxId,
        blockchain: tx.receiveBlockchain,
      );
      return [
        InCardActionButton(
          label: t.tx_detail_view_send,
          subtitle: tx.sendBlockchain!.shortName,
          icon: Icons.call_made,
          onPressed:
              sendEnabled
                  ? () => _openInExplorer(
                    txId: tx.sendTxId,
                    blockchain: tx.sendBlockchain,
                  )
                  : null,
        ),
        InCardActionButton(
          label: t.tx_detail_view_receive,
          subtitle: tx.receiveBlockchain!.shortName,
          icon: Icons.call_received,
          onPressed:
              receiveEnabled
                  ? () => _openInExplorer(
                    txId: tx.receiveTxId,
                    blockchain: tx.receiveBlockchain,
                  )
                  : null,
        ),
      ];
    }

    // Refunded peg: same chain on both sides but two distinct txids.
    // The default branch below would try to open the synthetic
    // `{send}_{receive}_refund` id in a block explorer and 404 — give
    // the user one button per real txid instead.
    if (_isRefundedSwap()) {
      final chainName = tx.sendBlockchain?.shortName ?? '';
      final sendEnabled = _isExplorerEnabledFor(
        txId: tx.sendTxId,
        blockchain: tx.sendBlockchain,
      );
      final refundEnabled = _isExplorerEnabledFor(
        txId: tx.receiveTxId,
        blockchain: tx.receiveBlockchain,
      );
      return [
        InCardActionButton(
          label: t.tx_detail_view_send_tx,
          subtitle: chainName,
          icon: Icons.call_made,
          onPressed:
              sendEnabled
                  ? () => _openInExplorer(
                    txId: tx.sendTxId,
                    blockchain: tx.sendBlockchain,
                  )
                  : null,
        ),
        InCardActionButton(
          label: t.tx_detail_view_refund_tx,
          subtitle: chainName,
          icon: Icons.call_received,
          onPressed:
              refundEnabled
                  ? () => _openInExplorer(
                    txId: tx.receiveTxId,
                    blockchain: tx.receiveBlockchain,
                  )
                  : null,
        ),
      ];
    }

    return [
      InCardActionButton(
        label: t.pix_deposit_view_explorer,
        subtitle: t.pix_deposit_view_chain,
        icon: Icons.open_in_new,
        onPressed: _isExplorerEnabledFor() ? () => _openInExplorer() : null,
      ),
      if (tx.blockchain == Blockchain.lightning &&
          tx.destination != null &&
          tx.preimage != null)
        InCardActionButton(
          label: t.tx_detail_validate_payment,
          subtitle: t.tx_detail_verify_preimage,
          icon: Icons.verified,
          onPressed: () => _openValidationUrl(),
        ),
    ];
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
    return useBlockchain.explorerUrl(useTxId);
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
        AppSnackBar.warning(
          context,
          AppLocalizations.of(context).error_open_browser_link_copied,
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
        AppSnackBar.warning(
          context,
          AppLocalizations.of(context).error_open_browser_link_copied,
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
      DetailRow(
        label: t.tx_detail_send_id_label(
          widget.transaction.sendBlockchain!.shortName,
        ),
        value: sendTxId == null ? '—' : truncateHashId(sendTxId),
        copyable: sendTxId != null,
        copyValue: sendTxId ?? '',
      ),
      DetailRow(
        label: t.tx_detail_receive_id_label(
          widget.transaction.receiveBlockchain!.shortName,
        ),
        value: receiveTxId == null ? '—' : truncateHashId(receiveTxId),
        copyable: receiveTxId != null,
        copyValue: receiveTxId ?? '',
      ),
    ];
  }

  /// Refund-specific dual id rendering. Labels lean on the
  /// existing send/receive l10n keys but explicitly mention "refund"
  /// in the receive slot so the user understands the second tx is
  /// not the swap's destination credit, it's the funds coming back.
  List<Widget> _buildRefundedSwapIds() {
    final t = AppLocalizations.of(context);
    final chainSuffix =
        widget.transaction.sendBlockchain == null
            ? ''
            : ' (${widget.transaction.sendBlockchain!.shortName})';
    return [
      DetailRow(
        label: '${t.tx_detail_send_tx_id}$chainSuffix',
        value: truncateHashId(widget.transaction.sendTxId!),
        copyable: true,
        copyValue: widget.transaction.sendTxId!,
      ),
      DetailRow(
        label: '${t.tx_detail_refund_tx_id}$chainSuffix',
        value: truncateHashId(widget.transaction.receiveTxId!),
        copyable: true,
        copyValue: widget.transaction.receiveTxId!,
      ),
    ];
  }
}
