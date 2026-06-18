import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/utils/formatters.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

class PixDepositDetailScreen extends StatefulWidget {
  final PixDeposit deposit;

  const PixDepositDetailScreen({super.key, required this.deposit});

  @override
  State<PixDepositDetailScreen> createState() => _PixDepositDetailScreenState();
}

class _PixDepositDetailScreenState extends State<PixDepositDetailScreen> {
  static const _pixValidityDuration = Duration(minutes: 20);

  final Map<String, bool> _copiedFields = {};
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  bool get _isPending => widget.deposit.status == DepositStatus.pending;

  @override
  void initState() {
    super.initState();
    if (_isPending) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    final expiresAt = widget.deposit.createdAt.add(_pixValidityDuration);
    _remaining = expiresAt.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final newRemaining = expiresAt.difference(DateTime.now());
      setState(() {
        _remaining = newRemaining.isNegative ? Duration.zero : newRemaining;
      });
      if (_remaining == Duration.zero) {
        _countdownTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PlatformSafeArea(
      child: Scaffold(
        backgroundColor: context.colors.backgroundColor,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            t.pix_deposit_title,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDepositHeader(t),
              const SizedBox(height: 20),
              if (_isPending) ...[
                _buildCountdownCard(t),
                const SizedBox(height: 20),
              ],
              _buildDetailsCard(context, t),
              const SizedBox(height: 20),
              if (widget.deposit.blockchainTxid != null)
                _buildActionButton(
                  context: context,
                  label: t.pix_deposit_view_explorer,
                  subtitle: t.pix_deposit_view_chain,
                  icon: Icons.open_in_new,
                  onPressed: _openInExplorer,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepositHeader(AppLocalizations t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.pix,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.pix_deposit_label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amountStr,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.positiveColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final statusColor = widget.deposit.status.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 16, color: statusColor),
          const SizedBox(width: 6),
          Text(
            widget.deposit.status.localizedLabel(context),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard(AppLocalizations t) {
    final isExpired = _remaining == Duration.zero;
    final isUrgent = _remaining.inMinutes < 5;
    final color =
        isExpired
            ? Theme.of(context).colorScheme.error
            : isUrgent
            ? context.appColors.warning
            : Theme.of(context).colorScheme.primary;

    final mm = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isExpired ? Icons.timer_off : Icons.timer_outlined,
              size: 22,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired
                      ? t.pix_deposit_expired
                      : t.pix_deposit_time_remaining,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isExpired ? t.pix_deposit_invalid : '$mm:$ss',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: isExpired ? 0.2 : 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (widget.deposit.status) {
      case DepositStatus.finished:
      case DepositStatus.completed:
      case DepositStatus.refunded:
        return Icons.check_circle;
      case DepositStatus.failed:
      case DepositStatus.expired:
      case DepositStatus.timeout:
        return Icons.cancel;
      case DepositStatus.med:
      case DepositStatus.unknown:
        return Icons.info_outline;
      case DepositStatus.processingRefund:
      case DepositStatus.broadcastedRefund:
        return Icons.refresh;
      default:
        return Icons.schedule;
    }
  }

  Widget _buildDetailsCard(BuildContext context, AppLocalizations t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.pix_deposit_info,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.access_time,
            label: t.pix_deposit_date,
            value: _formatDateTime(widget.deposit.createdAt),
          ),
          _buildInfoRow(
            icon: Icons.monetization_on,
            label: t.pix_deposit_target_asset,
            value: widget.deposit.asset.name,
          ),
          _buildInfoRow(
            icon: Icons.account_balance_wallet,
            label: t.pix_deposit_value,
            value: amountStr,
          ),
          _buildInfoRow(
            icon: Icons.key,
            label: t.pix_deposit_pix_key,
            value: truncateHashId(widget.deposit.pixKey),
            copyable: true,
            copyFieldId: 'pixKey',
            copyValue: widget.deposit.pixKey,
          ),
          _buildInfoRow(
            icon: Icons.tag,
            label: t.pix_deposit_id,
            value: truncateHashId(widget.deposit.depositId),
            copyable: true,
            copyFieldId: 'depositId',
            copyValue: widget.deposit.depositId,
          ),
          if (widget.deposit.assetAmount != null &&
              widget.deposit.status == DepositStatus.finished)
            _buildInfoRow(
              icon: Icons.arrow_downward,
              label: t.pix_deposit_received_value,
              value:
                  widget.deposit.asset.formatAsSatoshis(widget.deposit.assetAmount!),
            ),
          if (widget.deposit.blockchainTxid != null)
            _buildInfoRow(
              icon: Icons.link,
              label: t.pix_deposit_tx_id,
              value: truncateHashId(widget.deposit.blockchainTxid!),
              copyable: true,
              copyFieldId: 'txId',
              copyValue: widget.deposit.blockchainTxid!,
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
    final fieldId = copyFieldId ?? label;
    final isCopied = _copiedFields[fieldId] ?? false;
    final valueToCopy = copyValue ?? value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(valueToCopy, fieldId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isCopied
                            ? context.colors.positiveColor.withValues(
                              alpha: 0.2,
                            )
                            : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCopied ? Icons.check : Icons.copy,
                    size: 16,
                    color:
                        isCopied
                            ? context.colors.positiveColor
                            : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    return formatter.format(dateTime);
  }

  String _formatAmount(int amountInCents) {
    final amount = amountInCents / 100;
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    ).format(amount);
  }

  String get amountStr => 'R\$ ${_formatAmount(widget.deposit.amountInCents)}';

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

  Future<void> _openInExplorer() async {
    if (widget.deposit.blockchainTxid == null) return;

    String explorerUrl;
    switch (widget.deposit.asset.id) {
      case 'bitcoin':
        explorerUrl =
            'https://blockstream.info/tx/${widget.deposit.blockchainTxid}';
        break;
      case 'tether':
      case 'depix':
        explorerUrl =
            'https://blockstream.info/liquid/tx/${widget.deposit.blockchainTxid}';
        break;
      default:
        explorerUrl =
            'https://blockstream.info/tx/${widget.deposit.blockchainTxid}';
        break;
    }

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
        AppSnackBar.warning(
          context,
          AppLocalizations.of(context).error_open_browser,
        );
      }
    }
  }
}
