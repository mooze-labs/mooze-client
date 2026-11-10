import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/conversion_strip.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_detail_scaffold.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_meta_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_status_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail_row.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/hero_amount.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/in_card_action_button.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/info_banner.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/utils/transaction_display_x.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/utils/transaction_fee_x.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/shared/widgets.dart';

/// Details of one wallet transaction.
///
/// The hero states what happened: the coin, the kind of transaction, and
/// the amount at display size. The status panel follows: the status, the
/// date, and a track of the steps the transaction went through. A swap then
/// shows one strip with both sides and the rate. State notes come next, and
/// one glass panel holds the metadata: a compact grid of short facts, the
/// identifiers with copy, and the links that leave the app. The hero takes
/// the free height of the screen, so the cards stack below it as one group.
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
    final tx = widget.transaction;
    final isSendOrReceive =
        tx.type == TransactionType.send || tx.type == TransactionType.receive;
    final details = isSendOrReceive ? _sendReceiveDetails() : _swapDetails();

    return TxDetailScaffold(
      title: AppLocalizations.of(context).tx_detail_title,
      entranceKey: 'tx-detail-${tx.id}',
      hero: _buildHero(),
      sections: [
        _buildStatus(),
        if (_usesSwapHero)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildConversion(),
          ),
        for (final banner in details.banners)
          Padding(padding: const EdgeInsets.only(top: 12), child: banner),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TxMetaPanel(
            cells: details.cells,
            ids: details.ids,
            links: details.links,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Hero — what happened, at a glance: the coin(s), the kind, and the
  // amount that matters most (the amount moved, or what a swap brought in).
  // ─────────────────────────────────────────────────────────────────────

  bool get _isRefundableOrFailed =>
      widget.transaction.status == TransactionStatus.refundable ||
      widget.transaction.status == TransactionStatus.failed;

  /// Swaps and refunds with both sides known show the two coins and the
  /// conversion strip; every other transaction shows one coin.
  bool get _usesSwapHero {
    final type = widget.transaction.type;
    final isSwap =
        type == TransactionType.swap || type == TransactionType.submarine;
    return (_isRefundableOrFailed || isSwap) && _hasSwapDetails();
  }

  Widget _buildHero() {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    final currencySymbol = ref.watch(currencySymbolProvider);
    final failed = tx.status == TransactionStatus.failed;

    if (_usesSwapHero) {
      // An unfinished or refunded swap never brought the amount in, so it
      // is the expected amount: no sign, no green.
      final settled = !_isRefundableOrFailed;
      return Column(
        children: [
          HeroSwapIcon(
            fromAsset: tx.fromAsset!,
            toAsset: tx.toAsset!,
            isRefund: _isRefundedSwap(),
          ),
          const SizedBox(height: 14),
          _heroCaption(settled ? tx.type.label(t) : t.tx_detail_expected),
          const SizedBox(height: 2),
          HeroAmount(
            asset: tx.toAsset!,
            amountInSats: tx.receivedAmount!,
            currencySymbol: currencySymbol,
            sign: settled ? '+' : null,
            isIncoming: settled,
            struckThrough: failed,
          ),
        ],
      );
    }

    final isReceive = tx.type == TransactionType.receive;
    final isSend = tx.type == TransactionType.send;
    final glyph = switch (tx.type) {
      TransactionType.send => Icons.north_east,
      TransactionType.receive => Icons.south_west,
      TransactionType.redeposit => Icons.replay,
      _ => null,
    };
    return Column(
      children: [
        HeroAssetIcon(asset: tx.asset, glyph: glyph),
        const SizedBox(height: 14),
        _heroCaption(tx.type.label(t)),
        const SizedBox(height: 2),
        HeroAmount(
          asset: tx.asset,
          amountInSats: tx.amount,
          currencySymbol: currencySymbol,
          // The sign carries the direction, so it never depends on color.
          sign: isReceive ? '+' : (isSend ? '−' : null),
          isIncoming: isReceive,
          struckThrough: failed,
        ),
      ],
    );
  }

  /// The muted line above the hero amount: the kind of transaction, or
  /// "Expected" for a swap that has not brought its amount in.
  Widget _heroCaption(String text) => Text(
    text,
    style: context.textTheme.bodyMedium?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w500,
    ),
  );

  // ─────────────────────────────────────────────────────────────────────
  // Status — the state as a title, the date and confirmations below it, and
  // the track of steps the transaction went through.
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStatus() {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    final isSwapLike =
        _usesSwapHero ||
        tx.type == TransactionType.swap ||
        tx.type == TransactionType.submarine;

    final details = [_formatLocalizedDateTime(tx.createdAt)];
    // A Bitcoin transaction counts its confirmations until it settles.
    if (tx.blockchain == Blockchain.bitcoin &&
        tx.status != TransactionStatus.confirmed &&
        !_isRefundableOrFailed) {
      final confirmations = _getConfirmations();
      details.add(
        confirmations == null
            ? t.common_verifying
            : t.tx_detail_confirmations_progress(
                confirmations.clamp(0, 6).toInt(),
              ),
      );
    }

    return TxStatusPanel(
      icon: switch (tx.status) {
        TransactionStatus.confirmed => Icons.check_rounded,
        TransactionStatus.pending => Icons.schedule_rounded,
        TransactionStatus.refundable => Icons.priority_high_rounded,
        TransactionStatus.failed =>
          isSwapLike ? Icons.undo_rounded : Icons.close_rounded,
      },
      title: isSwapLike ? tx.status.swapLabel(t) : tx.status.label(t),
      color: tx.statusColor(context),
      details: details,
      steps: _statusSteps(t, isSwapLike),
    );
  }

  /// Three steps: the start, the network or conversion step, and the end.
  /// The middle step carries a failure or a refund.
  List<TxStep> _statusSteps(AppLocalizations t, bool isSwapLike) {
    final tx = widget.transaction;
    final first = isSwapLike
        ? t.tx_detail_sent
        : tx.type == TransactionType.receive
        ? t.tx_step_detected
        : t.tx_step_created;
    final middle = isSwapLike ? t.tx_step_converting : t.tx_step_on_network;
    final last = isSwapLike ? t.tx_detail_received : t.tx_status_confirmed_fem;

    return switch (tx.status) {
      TransactionStatus.confirmed => [
        TxStep(first, TxStepState.done),
        TxStep(middle, TxStepState.done),
        TxStep(last, TxStepState.done),
      ],
      TransactionStatus.pending => [
        TxStep(first, TxStepState.done),
        TxStep(middle, TxStepState.active),
        TxStep(last, TxStepState.upcoming),
      ],
      TransactionStatus.refundable || TransactionStatus.failed => [
        TxStep(first, TxStepState.done),
        TxStep(
          isSwapLike ? tx.status.swapLabel(t) : tx.status.label(t),
          TxStepState.failed,
        ),
        TxStep(last, TxStepState.upcoming),
      ],
    };
  }

  /// Both sides of the swap and, for a finished swap, the rate it got.
  Widget _buildConversion() {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    final settled = !_isRefundableOrFailed;
    return ConversionStrip(
      from: ConversionLeg(
        label: t.tx_detail_sent,
        asset: tx.fromAsset!,
        amountInSats: tx.sentAmount!,
        fiat: _fiatEstimateFor(tx.fromAsset!, tx.sentAmount!),
      ),
      to: ConversionLeg(
        label: settled ? t.tx_detail_received : t.tx_detail_expected,
        asset: tx.toAsset!,
        amountInSats: tx.receivedAmount!,
        fiat: _fiatEstimateFor(tx.toAsset!, tx.receivedAmount!),
      ),
      rate: settled ? _rateLine() : null,
    );
  }

  /// "1 DEPIX = 227 SATS": the received amount for one whole unit of the
  /// sent asset. Null when the rate means nothing, such as a peg of one
  /// asset to itself.
  String? _rateLine() {
    final tx = widget.transaction;
    final sent = tx.sentAmount!;
    final received = tx.receivedAmount!;
    if (sent <= BigInt.zero ||
        received <= BigInt.zero ||
        tx.fromAsset == tx.toAsset) {
      return null;
    }
    // Amounts are in base units (1e8 per whole unit) on both sides.
    final perUnit = received.toDouble() * 100000000 / sent.toDouble();
    final from = tx.fromAsset!;
    final locale = Localizations.localeOf(context).toString();
    return AppLocalizations.of(context).swap_rate_line(
      // One whole unit of a BTC-like asset is one coin, not one sat.
      from == Asset.btc || from == Asset.lbtc ? from.ticker : from.displayUnit,
      tx.toAsset!.formatAmount(perUnit.round(), locale: locale),
      conversionUnit(tx.toAsset!),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Details — state notes, the metadata grid, the identifiers, and the
  // links, gathered per transaction kind.
  // ─────────────────────────────────────────────────────────────────────

  _Details _sendReceiveDetails() {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    final banners = <Widget>[];
    final ids = <Widget>[];

    final cells = <MetaCell>[
      MetaCell(t.tx_detail_blockchain, tx.blockchain.networkLabel),
      _assetCell(tx.asset),
      ?_feeCell(t),
    ];

    if (tx.id.isNotEmpty) {
      ids.add(
        DetailRow(
          label: t.tx_id,
          value: truncateHashId(tx.id),
          copyable: true,
          copyValue: tx.id,
        ),
      );
    }
    _addLightningIds(ids, banners, t);

    return (
      banners: banners,
      cells: cells,
      ids: ids,
      links: _buildSendReceiveActions(context),
    );
  }

  _Details _swapDetails() {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    final isSwap = tx.type == TransactionType.swap;
    final isSubmarineSwap = tx.type == TransactionType.submarine;
    final confirmed = tx.status == TransactionStatus.confirmed;

    final banners = <Widget>[];
    final cells = <MetaCell>[
      MetaCell(t.tx_detail_blockchain, tx.blockchain.networkLabel),
    ];
    final ids = <Widget>[];

    if (_isRefundableOrFailed) {
      // The conversion strip shows the sent and expected assets.
      if (_feeCell(t) case final fee?) cells.add(fee);
      // Refunded peg (`{sendId}_{receiveId}_refund` synthetic id, NOT a chain
      // txid) → render the two real txids separately instead of leaking the
      // synthetic id to the user as if it were valid.
      if (_isRefundedSwap()) {
        ids.addAll(_buildRefundedSwapIds());
      } else if (tx.id.isNotEmpty) {
        ids.add(
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

      if (!(isSwap && _hasSwapDetails())) cells.add(_assetCell(tx.asset));
      if (_feeCell(t) case final fee?) cells.add(fee);

      if (isSwap && _isCrossChainSwap()) {
        ids.addAll(_buildCrossChainSwapIds());
      } else if (isSwap && _isRefundedSwap()) {
        ids.addAll(_buildRefundedSwapIds());
      } else {
        ids.add(
          DetailRow(
            label: t.tx_id,
            value: truncateHashId(tx.id),
            copyable: true,
            copyValue: tx.id,
          ),
        );
      }
      _addLightningIds(ids, banners, t);
    }

    return (
      banners: banners,
      cells: cells,
      ids: ids,
      links: _buildSwapActions(context),
    );
  }

  /// The invoice or LNURL and the preimage of a Lightning payment. A
  /// pending payment without a preimage gets a note instead.
  void _addLightningIds(
    List<Widget> ids,
    List<Widget> banners,
    AppLocalizations t,
  ) {
    final tx = widget.transaction;
    if (tx.blockchain != Blockchain.lightning) return;
    if (tx.destination != null) {
      ids.add(
        DetailRow(
          label: tx.type == TransactionType.send ? 'LNURL' : 'Invoice',
          value: truncateHashId(tx.destination!),
          copyable: true,
          copyValue: tx.destination!,
        ),
      );
    }
    if (tx.preimage != null) {
      ids.add(
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

  MetaCell _assetCell(Asset asset) => MetaCell(
    AppLocalizations.of(context).wallet_send_conversion_asset,
    asset.name,
    leading: SvgPicture.asset(asset.iconPath, width: 18, height: 18),
  );

  MetaCell? _feeCell(AppLocalizations t) {
    final feeSat = widget.transaction.totalFeeSat;
    if (feeSat == null) return null;
    return MetaCell(t.tx_detail_fee, _formatFeeSats(feeSat));
  }

  String _formatFeeSats(BigInt feeSat) {
    final unit = feeSat == BigInt.one ? 'sat' : 'sats';
    final locale = ref.read(localeStringProvider);
    return '${NumberFormat('#,##0', locale).format(feeSat.toInt())} $unit';
  }

  List<Widget> _buildSendReceiveActions(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    return [
      InCardActionButton(
        label: t.pix_deposit_view_explorer,
        subtitle: _effectiveExplorerBlockchain().networkLabel,
        icon: Icons.travel_explore_rounded,
        onPressed: _isExplorerEnabledFor() ? () => _openInExplorer() : null,
      ),
      if (tx.blockchain == Blockchain.lightning &&
          tx.destination != null &&
          tx.preimage != null)
        InCardActionButton(
          label: t.tx_detail_validate_payment,
          subtitle: t.tx_detail_verify_preimage,
          icon: Icons.verified_rounded,
          onPressed: () => _openValidationUrl(),
        ),
    ];
  }

  /// The date in its short form, so it fits one line of the status panel.
  String _formatLocalizedDateTime(DateTime dateTime) {
    final locale = ref.read(localeStringProvider);
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final datePart = DateFormat.yMMMd(locale).format(dateTime);
    final timePart = (use24h ? DateFormat.Hm(locale) : DateFormat.jm(locale))
        .format(dateTime);
    return AppLocalizations.of(context).tx_detail_datetime(datePart, timePart);
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
  // Links — rows of the links panel. Disabled links dim, enabled ones
  // ripple.
  // ─────────────────────────────────────────────────────────────────────

  /// Links of the swap/refund details, in the same links panel as
  /// send/receive.
  List<Widget> _buildSwapActions(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;

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
          onPressed: sendEnabled
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
          onPressed: receiveEnabled
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
          onPressed: sendEnabled
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
          onPressed: refundEnabled
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
        subtitle: _effectiveExplorerBlockchain().networkLabel,
        icon: Icons.travel_explore_rounded,
        onPressed: _isExplorerEnabledFor() ? () => _openInExplorer() : null,
      ),
      if (tx.blockchain == Blockchain.lightning &&
          tx.destination != null &&
          tx.preimage != null)
        InCardActionButton(
          label: t.tx_detail_validate_payment,
          subtitle: t.tx_detail_verify_preimage,
          icon: Icons.verified_rounded,
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
    final chainSuffix = widget.transaction.sendBlockchain == null
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

/// The parts of the details area of one transaction.
typedef _Details = ({
  List<Widget> banners,
  List<MetaCell> cells,
  List<Widget> ids,
  List<Widget> links,
});
