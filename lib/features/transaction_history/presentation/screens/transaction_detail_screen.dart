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
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/swap/presentation/widgets/swap_deal_card.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/transaction_indicator_badge.dart';
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
              _buildTransactionHeader(isReceive, bitcoinPrice, currencySymbol),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRefundableOrFailed && _hasSwapDetails())
          _buildRefundableHeader()
        else if (isSwap && _hasSwapDetails())
          _buildSwapHeader()
        else
          _buildRegularHeader(isReceive, bitcoinPrice, currencySymbol),
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

  Widget _buildRegularHeader(
    bool isReceive,
    AsyncValue<double> bitcoinPrice,
    String currencySymbol,
  ) {
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
          _getTransactionTypeLabel(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isReceive ? colors.positiveColor : colors.negativeColor,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 20),
        _SoftCard(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroAmount(
                asset: tx.asset,
                amountInSats: tx.amount,
                isReceive: isReceive,
                bitcoinPrice: bitcoinPrice,
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: _heroDividerColor(theme)),
              const SizedBox(height: 14),
              _buildHeroAssetRow(tx.asset),
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

  Widget _buildHeroAssetRow(Asset asset) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SvgPicture.asset(asset.iconPath, width: 32, height: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).wallet_send_conversion_asset,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                asset.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          asset.ticker,
          style: theme.textTheme.labelMedium?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSendReceiveCard(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    final isLightning = tx.blockchain == Blockchain.lightning;

    final banners = <Widget>[];
    final rows = <Widget>[];

    if (tx.blockchain == Blockchain.bitcoin &&
        tx.status != TransactionStatus.confirmed) {
      banners.add(_buildConfirmationRow());
    }

    rows.add(_buildStatusRow());
    rows.add(
      _buildPlainRow(
        label: t.pix_deposit_date,
        value: _formatLocalizedDateTime(tx.createdAt),
      ),
    );
    rows.add(_buildAssetRow(tx.asset));
    rows.add(
      _buildPlainRow(
        label: t.wallet_amount,
        value:
            '${(tx.amount.toDouble() / 100000000).toStringAsFixed(8)} ${tx.asset.ticker}',
      ),
    );
    rows.add(
      _buildPlainRow(
        label: t.tx_detail_blockchain,
        value: _getBlockchainLabel(),
      ),
    );

    if (tx.id.isNotEmpty) {
      rows.add(
        _buildPlainRow(
          label: t.tx_id,
          value: truncateHashId(tx.id),
          copyable: true,
          copyFieldId: 'transaction_id',
          copyValue: tx.id,
        ),
      );
    }

    if (isLightning) {
      if (tx.destination != null) {
        rows.add(
          _buildPlainRow(
            label: tx.type == TransactionType.send ? 'LNURL' : 'Invoice',
            value: truncateHashId(tx.destination!),
            copyable: true,
            copyFieldId: 'destination',
            copyValue: tx.destination!,
          ),
        );
      }
      if (tx.preimage != null) {
        rows.add(
          _buildPlainRow(
            label: t.tx_detail_preimage_label,
            value: truncateHashId(tx.preimage!),
            copyable: true,
            copyFieldId: 'preimagem',
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
    return _SoftCard(
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

  Widget _buildPlainRow({
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
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
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

  Widget _buildTrailingWidgetRow({
    required String label,
    required Widget trailing,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }

  /// "Asset" row — the asset icon to the left of its name. The asset is its own
  /// identifier here, so the row carries no separate text value.
  Widget _buildAssetRow(Asset asset) {
    final theme = Theme.of(context);
    return _buildTrailingWidgetRow(
      label: AppLocalizations.of(context).wallet_send_conversion_asset,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(asset.iconPath, width: 22, height: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              asset.name,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    return _buildTrailingWidgetRow(
      label: AppLocalizations.of(context).tx_filter_status,
      trailing: _buildStatusChip(),
    );
  }

  Widget _buildStatusChip() {
    final theme = Theme.of(context);
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _getStatusLabel(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSendReceiveActions(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tx = widget.transaction;
    final actions = <Widget>[];

    actions.add(
      _buildInCardActionButton(
        context: context,
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
        _buildInCardActionButton(
          context: context,
          label: t.tx_detail_validate_payment,
          subtitle: t.tx_detail_verify_preimage,
          icon: Icons.verified,
          onPressed: () => _openValidationUrl(),
        ),
      );
    }
    return actions;
  }

  Widget _buildInCardActionButton({
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

    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isPrimary ? accent : accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: isPrimary ? cs.onPrimary : accent,
            ),
          ),
          const SizedBox(width: 12),
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
            size: 14,
            color: context.colors.textTertiary,
          ),
        ],
      ),
    );

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isPrimary ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: isPrimary ? 0.30 : 0.16),
          ),
        ),
        child:
            enabled
                ? Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(onTap: onPressed, child: body),
                )
                : body,
      ),
    );
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
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = _getStatusColor();

    final IconData icon;
    final String label;
    switch (widget.transaction.status) {
      case TransactionStatus.confirmed:
        icon = Icons.check_circle_rounded;
        label = t.tx_detail_swap_completed;
      case TransactionStatus.pending:
        icon = Icons.schedule_rounded;
        label = t.tx_detail_swap_in_progress;
      case TransactionStatus.refundable:
        icon = Icons.warning_amber_rounded;
        label = t.tx_detail_swap_unfinished;
      case TransactionStatus.failed:
        icon = Icons.assignment_return_rounded;
        label = t.tx_detail_swap_refunded;
    }
    return Column(
      children: [
        TransactionIndicatorBadge(icon: icon, color: color, size: 72),
        const SizedBox(height: 14),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.2,
          ),
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

  String? _fiatEstimateFor(Asset asset, BigInt amount) {
    return ref
        .watch(fiatPriceProvider(asset))
        .maybeWhen(
          data: (either) {
            return either.fold((_) => null, (price) {
              if (price <= 0) return null;
              final symbol = ref.watch(currencySymbolProvider);
              final formatter = NumberFormat(
                '#,##0.00',
                ref.watch(localeStringProvider),
              );
              return '$symbol ${formatter.format(asset.toUsd(amount, price))}';
            });
          },
          orElse: () => null,
        );
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
        _buildPlainRow(
          label: t.pix_deposit_date,
          value: _formatLocalizedDateTime(tx.createdAt),
        ),
      );
      if (_hasSwapDetails()) {
        rows.add(
          _buildPlainRow(label: t.tx_detail_sent, value: tx.fromAsset!.ticker),
        );
        rows.add(
          _buildPlainRow(
            label: t.tx_detail_expected,
            value: tx.toAsset!.ticker,
          ),
        );
      }
      rows.add(
        _buildPlainRow(
          label: t.tx_detail_blockchain,
          value: _getBlockchainLabel(),
        ),
      );
      // Refunded peg (`{sendId}_{receiveId}_refund` synthetic id, NOT a chain
      // txid) → render the two real txids separately instead of leaking the
      // synthetic id to the user as if it were valid.
      if (_isRefundedSwap()) {
        rows.addAll(_buildRefundedSwapIds());
      } else if (tx.id.isNotEmpty) {
        rows.add(
          _buildPlainRow(
            label: t.tx_id,
            value: truncateHashId(tx.id),
            copyable: true,
            copyFieldId: 'transaction_id',
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
        banners.add(_buildConfirmationRow());
      }

      rows.add(_buildStatusRow());
      rows.add(
        _buildPlainRow(
          label: t.pix_deposit_date,
          value: _formatLocalizedDateTime(tx.createdAt),
        ),
      );

      if (!(isSwap && _hasSwapDetails())) {
        rows.add(
          _buildPlainRow(label: t.tx_filter_currency, value: tx.asset.name),
        );
        rows.add(
          _buildPlainRow(
            label: t.wallet_amount,
            value:
                '${(tx.amount.toDouble() / 100000000).toStringAsFixed(8)} ${tx.asset.ticker}',
          ),
        );
      }

      rows.add(
        _buildPlainRow(
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
          _buildPlainRow(
            label: t.tx_id,
            value: truncateHashId(tx.id),
            copyable: true,
            copyFieldId: 'transaction_id',
            copyValue: tx.id,
          ),
        );
      }

      if (tx.blockchain == Blockchain.lightning) {
        if (tx.destination != null) {
          rows.add(
            _buildPlainRow(
              label: tx.type == TransactionType.send ? "LNURL" : "Invoice",
              value: truncateHashId(tx.destination!),
              copyable: true,
              copyFieldId: 'destination',
              copyValue: tx.destination!,
            ),
          );
        }
        if (tx.preimage != null) {
          rows.add(
            _buildPlainRow(
              label: t.tx_detail_preimage_label,
              value: truncateHashId(tx.preimage!),
              copyable: true,
              copyFieldId: 'preimagem',
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
        _buildInCardActionButton(
          context: context,
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
        _buildInCardActionButton(
          context: context,
          label: t.tx_detail_view_send,
          subtitle: _getBlockchainName(tx.sendBlockchain!),
          icon: Icons.call_made,
          onPressed:
              sendEnabled
                  ? () => _openInExplorer(
                    txId: tx.sendTxId,
                    blockchain: tx.sendBlockchain,
                  )
                  : null,
        ),
        _buildInCardActionButton(
          context: context,
          label: t.tx_detail_view_receive,
          subtitle: _getBlockchainName(tx.receiveBlockchain!),
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
      final chainName =
          tx.sendBlockchain == null
              ? ''
              : _getBlockchainName(tx.sendBlockchain!);
      final sendEnabled = _isExplorerEnabledFor(
        txId: tx.sendTxId,
        blockchain: tx.sendBlockchain,
      );
      final refundEnabled = _isExplorerEnabledFor(
        txId: tx.receiveTxId,
        blockchain: tx.receiveBlockchain,
      );
      return [
        _buildInCardActionButton(
          context: context,
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
        _buildInCardActionButton(
          context: context,
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
      _buildInCardActionButton(
        context: context,
        label: t.pix_deposit_view_explorer,
        subtitle: t.pix_deposit_view_chain,
        icon: Icons.open_in_new,
        onPressed: _isExplorerEnabledFor() ? () => _openInExplorer() : null,
      ),
      if (tx.blockchain == Blockchain.lightning &&
          tx.destination != null &&
          tx.preimage != null)
        _buildInCardActionButton(
          context: context,
          label: t.tx_detail_validate_payment,
          subtitle: t.tx_detail_verify_preimage,
          icon: Icons.verified,
          onPressed: () => _openValidationUrl(),
        ),
    ];
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
      _buildPlainRow(
        label: t.tx_detail_send_id_label(
          _getBlockchainName(widget.transaction.sendBlockchain!),
        ),
        value: sendTxId == null ? '—' : truncateHashId(sendTxId),
        copyable: sendTxId != null,
        copyFieldId: 'send_tx_id',
        copyValue: sendTxId ?? '',
      ),
      _buildPlainRow(
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
    final t = AppLocalizations.of(context);
    final chainSuffix =
        widget.transaction.sendBlockchain == null
            ? ''
            : ' (${_getBlockchainName(widget.transaction.sendBlockchain!)})';
    return [
      _buildPlainRow(
        label: '${t.tx_detail_send_tx_id}$chainSuffix',
        value: truncateHashId(widget.transaction.sendTxId!),
        copyable: true,
        copyFieldId: 'send_tx_id',
        copyValue: widget.transaction.sendTxId!,
      ),
      _buildPlainRow(
        label: '${t.tx_detail_refund_tx_id}$chainSuffix',
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

    final borderColor =
        isDark
            ? cs.onSurface.withValues(alpha: 0.08)
            : cs.outline.withValues(alpha: 0.55);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color:
            isDark
                ? cs.onSurface.withValues(alpha: 0.05)
                : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
      ),
      child: child,
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
            ? '${SatsInputFormatter.formatValue(amountInSats.toInt())} sats'
            : '$decimalStr ${asset.ticker}';

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
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (isBtcLike) ...[
          const SizedBox(height: 8),
          Text(
            '$decimalStr ${asset.ticker}',
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
