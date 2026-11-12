import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_sheet.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_detail_scaffold.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_meta_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_status_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail_row.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/hero_amount.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/in_card_action_button.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/utils/formatters.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// Details of a Pix deposit, in the layout of the transaction detail.
///
/// From the top: the hero (the coin of the target asset, the kind, and the
/// amount in reais), the status card with the steps of the deposit, and
/// the details panel (facts, identifiers with copy, and the explorer
/// link). While a deposit waits for its payment, the status card counts
/// down the validity of the Pix, and the panel offers the actions of a
/// payment link: share the Pix code, or show it as a QR Code. A Pix past
/// its validity offers neither, as it would only fail for the payer.
class PixDepositDetailScreen extends StatefulWidget {
  final PixDeposit deposit;

  const PixDepositDetailScreen({super.key, required this.deposit});

  @override
  State<PixDepositDetailScreen> createState() => _PixDepositDetailScreenState();
}

/// Where a deposit is: done, failed, on its way, or unknown.
enum _Stage { done, failed, inProgress, unknown }

class _PixDepositDetailScreenState extends State<PixDepositDetailScreen> {
  static const _pixValidityDuration = Duration(minutes: 20);

  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  PixDeposit get _deposit => widget.deposit;

  bool get _isPending => _deposit.status == DepositStatus.pending;

  /// True while the Pix code still pays: pending, within its validity.
  bool get _canPay => _isPending && _remaining > Duration.zero;

  _Stage get _stage => switch (_deposit.status) {
    DepositStatus.depixSent ||
    DepositStatus.finished ||
    DepositStatus.completed ||
    DepositStatus.finishedRefund => _Stage.done,
    DepositStatus.failed ||
    DepositStatus.expired ||
    DepositStatus.timeout => _Stage.failed,
    DepositStatus.unknown => _Stage.unknown,
    _ => _Stage.inProgress,
  };

  @override
  void initState() {
    super.initState();
    if (_isPending) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    final expiresAt = _deposit.createdAt.add(_pixValidityDuration);
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
    return TxDetailScaffold(
      title: t.pix_deposit_title,
      entranceKey: 'pix-deposit-${_deposit.depositId}',
      hero: _buildHero(t),
      sections: [
        _buildStatus(t),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildDetails(t),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Hero — the coin of the target asset, the kind, and the amount.
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildHero(AppLocalizations t) {
    final stage = _stage;
    final failed = stage == _Stage.failed;
    final done = stage == _Stage.done;
    final digitsStyle = context.textTheme.displaySmall?.copyWith(
      // The money arrived: green. It never arrived: muted and struck.
      color: failed
          ? context.colors.textSecondary
          : done
          ? context.colors.positiveColor
          : context.colors.textPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: -1,
      height: 1.1,
      fontFeatures: const [FontFeature.tabularFigures()],
      decoration: failed ? TextDecoration.lineThrough : null,
    );
    final digits = formatBrlCents(
      _deposit.amountInCents,
    ).replaceFirst(RegExp(r'^R\$\s*'), '');
    final sign = done ? '+ ' : '';
    // The currency symbol is smaller and muted, as the unit of the
    // transaction hero.
    final symbolStyle = context.textTheme.titleLarge?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      decoration: failed ? TextDecoration.lineThrough : null,
    );

    return Column(
      children: [
        HeroAssetIcon(asset: _deposit.asset, glyph: Icons.south_west),
        const SizedBox(height: 14),
        Text(
          t.pix_deposit_label,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        // A long amount or a large text size scales the line down.
        Semantics(
          label: '${sign}R\$ $digits',
          excludeSemantics: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  if (sign.isNotEmpty) TextSpan(text: sign),
                  TextSpan(text: 'R\$ ', style: symbolStyle),
                  TextSpan(text: digits),
                ],
              ),
              maxLines: 1,
              style: digitsStyle,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Status — the state as a title, the date or the countdown below it, and
  // the steps of the deposit.
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStatus(AppLocalizations t) {
    final stage = _stage;
    final statusLabel = _deposit.status.localizedLabel(context);
    final (icon, color) = switch (stage) {
      _Stage.done => (Icons.check_rounded, context.colors.positiveColor),
      _Stage.failed => (Icons.close_rounded, context.colors.negativeColor),
      _Stage.inProgress => (Icons.schedule_rounded, context.appColors.warning),
      _Stage.unknown => (
        Icons.question_mark_rounded,
        context.colors.textSecondary,
      ),
    };

    final details = <String>[_formatDateTime(_deposit.createdAt)];
    if (_isPending) {
      if (_remaining == Duration.zero) {
        details.add(t.pix_deposit_invalid);
      } else {
        final mm = _remaining.inMinutes
            .remainder(60)
            .toString()
            .padLeft(2, '0');
        final ss = _remaining.inSeconds
            .remainder(60)
            .toString()
            .padLeft(2, '0');
        details.add('${t.pix_deposit_time_remaining} $mm:$ss');
      }
    }

    // Created, then the step in progress, then the coins in the wallet.
    // The middle step names the current status while the deposit is on its
    // way.
    final steps = switch (stage) {
      _Stage.done => [
        TxStep(t.tx_step_created, TxStepState.done),
        TxStep(t.tx_step_converting, TxStepState.done),
        TxStep(t.tx_detail_received, TxStepState.done),
      ],
      _Stage.failed => [
        TxStep(t.tx_step_created, TxStepState.done),
        TxStep(statusLabel, TxStepState.failed),
        TxStep(t.tx_detail_received, TxStepState.upcoming),
      ],
      _Stage.inProgress => [
        TxStep(t.tx_step_created, TxStepState.done),
        TxStep(statusLabel, TxStepState.active),
        TxStep(t.tx_detail_received, TxStepState.upcoming),
      ],
      _Stage.unknown => [
        TxStep(t.tx_step_created, TxStepState.done),
        TxStep(t.tx_step_converting, TxStepState.upcoming),
        TxStep(t.tx_detail_received, TxStepState.upcoming),
      ],
    };

    return TxStatusPanel(
      icon: icon,
      title: statusLabel,
      color: color,
      steps: steps,
      details: details,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Details — facts, identifiers with copy, and the explorer link.
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDetails(AppLocalizations t) {
    final asset = _deposit.asset;
    final received =
        _deposit.assetAmount != null &&
        _deposit.status == DepositStatus.finished;

    return TxMetaPanel(
      cells: [
        MetaCell(
          t.pix_deposit_target_asset,
          asset.name,
          leading: SvgPicture.asset(asset.iconPath, width: 18, height: 18),
        ),
        MetaCell(t.pix_deposit_value, formatBrlCents(_deposit.amountInCents)),
        if (received)
          MetaCell(
            t.pix_deposit_received_value,
            asset.formatAsSatoshis(_deposit.assetAmount!),
            wide: true,
          ),
      ],
      ids: [
        DetailRow(
          label: t.pix_deposit_pix_key,
          value: truncateHashId(_deposit.pixKey),
          copyable: true,
          copyValue: _deposit.pixKey,
        ),
        DetailRow(
          label: t.pix_deposit_id,
          value: truncateHashId(_deposit.depositId),
          copyable: true,
          copyValue: _deposit.depositId,
        ),
        if (_deposit.blockchainTxid != null)
          DetailRow(
            label: t.pix_deposit_tx_id,
            value: truncateHashId(_deposit.blockchainTxid!),
            copyable: true,
            copyValue: _deposit.blockchainTxid!,
          ),
      ],
      links: [
        if (_canPay) ...[
          InCardActionButton(
            label: t.pix_deposit_share_action,
            subtitle: t.pix_deposit_share_action_subtitle,
            icon: Icons.ios_share_rounded,
            onPressed: _share,
          ),
          InCardActionButton(
            label: t.pix_deposit_qr_action,
            subtitle: t.pix_deposit_qr_action_subtitle,
            icon: Icons.qr_code_2_rounded,
            // The QR Code opens in the app, not outside it.
            trailingIcon: Icons.chevron_right_rounded,
            onPressed: _showQrCode,
          ),
        ],
        if (_deposit.blockchainTxid != null)
          InCardActionButton(
            label: t.pix_deposit_view_explorer,
            subtitle: t.pix_deposit_view_chain,
            icon: Icons.open_in_new_rounded,
            onPressed: _openInExplorer,
          ),
      ],
    );
  }

  /// Shares the amount and the Pix code, for someone else to pay.
  Future<void> _share() async {
    final t = AppLocalizations.of(context);
    await SharePlus.instance.share(
      ShareParams(
        text: t.pix_deposit_share_message(
          formatBrlCents(_deposit.amountInCents),
          _deposit.pixKey,
        ),
      ),
    );
  }

  /// Shows the Pix code as a QR Code, for a payer in person.
  void _showQrCode() {
    final t = AppLocalizations.of(context);
    showPixQrSheet(
      context,
      data: _deposit.pixKey,
      subtitle: formatBrlCents(_deposit.amountInCents),
      caption: t.pix_deposit_qr_caption,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    return formatter.format(dateTime);
  }

  Future<void> _openInExplorer() async {
    if (_deposit.blockchainTxid == null) return;

    String explorerUrl;
    switch (_deposit.asset.id) {
      case 'bitcoin':
        explorerUrl = 'https://blockstream.info/tx/${_deposit.blockchainTxid}';
        break;
      case 'tether':
      case 'depix':
        explorerUrl =
            'https://blockstream.info/liquid/tx/${_deposit.blockchainTxid}';
        break;
      default:
        explorerUrl = 'https://blockstream.info/tx/${_deposit.blockchainTxid}';
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
