import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_header.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_operation_list.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_primary_action_cards.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_section_header.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_deposit_profile_service_provider.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_onboarding_service_provider.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/first_time_pix_dialog.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_limits_info_dialog.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/shared/widgets/motion/staggered_entrance.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Entry point of every Pix operation.
///
/// The screen keeps the identity of the home screen — same logo, same spacing
/// grid — and splits the area in three blocks: the title, the primary
/// shortcuts and the lists of operations and preferences.
///
/// The layout uses a 4 pt spacing scale. Tight text pairs use 2 pt half steps.
///
/// The five blocks enter with a staggered fade and rise, once per app
/// session (see [StaggeredEntrance]). A tab return shows them at once.
class PixHubScreen extends ConsumerStatefulWidget {
  const PixHubScreen({super.key});

  @override
  ConsumerState<PixHubScreen> createState() => _PixHubScreenState();
}

class _PixHubScreenState extends ConsumerState<PixHubScreen> {
  /// Distance that already counts as "scrolled away from the top".
  static const double _scrollThreshold = 4;

  /// Below this width the page gutter drops from 20 to 16.
  static const double _compactWidth = 360;

  /// Maximum content width on tablets and in landscape.
  static const double _maxContentWidth = 560;

  final ScrollController _scrollController = ScrollController();

  /// Drives the header background: transparent at the top, page color below.
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstAccess());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isScrolled = _scrollController.offset > _scrollThreshold;
    if (isScrolled != _isScrolled) {
      setState(() => _isScrolled = isScrolled);
    }
  }

  /// Shows the terms and the limits dialogs the first time the user opens Pix.
  ///
  /// The hub keeps this behaviour from the previous Pix screen so the existing
  /// onboarding is not lost.
  Future<void> _checkFirstAccess() async {
    final onboarding = ref.read(pixOnboardingServiceProvider);
    if (await onboarding.hasSeenFirstTimeDialog() || !mounted) return;

    final accepted = await FirstTimePixDialog.show(context);
    if (accepted != true || !mounted) return;

    await onboarding.markFirstTimeDialogAsSeen();
    if (mounted) await PixLimitsInfoDialog.show(context);
  }

  /// Opens the deposit flow, after the CPF and the ownership notice.
  void _openDeposit() {
    final profile = ref.read(pixDepositProfileServiceProvider);
    context.push(
      profile.isReadyToDeposit() ? '/pix/deposit' : '/pix/deposit/cpf',
    );
  }

  void _startSend(String route) {
    ref.read(pixSendControllerProvider.notifier).reset();
    context.push(route);
  }

  /// Guidance about how Pix works, including the deposit notice.
  void _showPixInfo() {
    final t = AppLocalizations.of(context);
    InfoOverlay.show(
      context,
      title: t.pix_hub_info_title,
      steps: [
        InfoStep(
          icon: Icons.bolt_rounded,
          title: t.pix_hub_info_send_title,
          description: t.pix_hub_info_send_body,
        ),
        InfoStep(
          icon: Icons.account_balance_wallet_outlined,
          title: t.pix_hub_info_deposit_title,
          description: t.pix_hub_info_deposit_body,
        ),
        InfoStep(
          icon: Icons.warning_amber_rounded,
          title: t.pix_hub_deposit_notice_title,
          description: t.pix_hub_deposit_notice_body,
        ),
      ],
      footerBuilder: (closeOverlay) => Column(
        children: [
          SecondaryButton(
            text: t.pix_hub_deposit_notice_screen_title,
            onPressed: () {
              closeOverlay();
              context.push('/pix/deposit/notice');
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              closeOverlay();
              context.push('/pix/fees');
            },
            child: Text(t.pix_hub_menu_fees),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // The shell scaffold draws the body under the navigation bar and reports
    // the bar height as bottom padding. The list ends above the bar.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // On wide screens the content keeps a readable width and stays centered.
    final width = MediaQuery.sizeOf(context).width;
    final gutter = math.max(
      width < _compactWidth ? 16.0 : 20.0,
      (width - _maxContentWidth) / 2,
    );

    // The safe area starts below the status bar. The header paints the
    // backdrop slice that starts there.
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          // The shared backdrop of the main screens, behind the status bar.
          const Positioned.fill(child: AppBackdrop()),
          PlatformSafeArea(
            iosTop: true,
            androidTop: true,
            androidBottom: false,
            // The header is pinned on top of the list, so the content
            // scrolls under it instead of pushing it away.
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    refreshPixHub(ref);
                    ref.invalidate(pixPendingWithdrawalsProvider);
                  },
                  displacement: PixHubHeader.height + 16,
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      PixHubHeader.height + 4,
                      gutter,
                      bottomInset + 24,
                    ),
                    children: [
                      StaggeredEntrance(
                        sessionKey: PixHubScreen,
                        // The list stretches its children. The entrance
                        // keeps that layout.
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        sections: [
                          const _HubTitle(),
                          _PrimaryActions(
                            onDeposit: _openDeposit,
                            onSend: _startSend,
                          ),
                          const _PendingWithdrawals(),
                          _HubSection(
                            title: t.pix_hub_other_operations,
                            child: _OtherOperations(onSend: _startSend),
                          ),
                          _HubSection(
                            title: t.pix_hub_preferences,
                            child: const _Preferences(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: PixHubHeader(
                    onScan: () => _startSend('/pix/send/scan'),
                    onInfo: _showPixInfo,
                    isScrolled: _isScrolled,
                    horizontalPadding: gutter,
                    backdropOrigin: topInset,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Space above each section below the primary actions.
const double _sectionGap = 32;

/// Space between a section title and its content.
const double _sectionTitleGap = 8;

/// The screen name and the line that explains the area.
///
/// The title is larger than the title of the inner Pix screens, because the
/// hub is the root of a tab.
class _HubTitle extends StatelessWidget {
  const _HubTitle();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            header: true,
            child: Text(
              t.pix_hub_title,
              style: context.textTheme.headlineMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.pix_hub_subtitle,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled section of the hub: the gap above, the title, and the content.
///
/// All sections use the same gaps, so the page keeps one rhythm.
class _HubSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _HubSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: _sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixSectionHeader(title: title),
          const SizedBox(height: _sectionTitleGap),
          child,
        ],
      ),
    );
  }
}

/// Receive as a full-width card, with send and deposit below it.
class _PrimaryActions extends StatelessWidget {
  final VoidCallback onDeposit;
  final void Function(String route) onSend;

  const _PrimaryActions({required this.onDeposit, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Column(
      children: [
        PixHighlightActionCard(
          icon: PixIcons.qrCode,
          label: t.pix_hub_shortcut_receive,
          description: t.pix_hub_shortcut_receive_description,
          onTap: () => context.push('/pix/receive'),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: PixCompactActionCard(
                  icon: PixIcons.send,
                  label: t.pix_hub_shortcut_send,
                  onTap: () => onSend('/pix/send'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PixCompactActionCard(
                  icon: PixIcons.deposit,
                  label: t.pix_hub_shortcut_deposit,
                  onTap: onDeposit,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Withdrawals whose DePix may have left the wallet without a final status.
///
/// The list comes from the local records, so a payment interrupted by a
/// restart stays visible. A tap opens the result screen, which reads the
/// status again.
///
/// The section grows and fades in when the first record appears, and
/// shrinks and fades out when the last one goes, over
/// [Motion.durationEmphasis]. With reduced motion, it changes at once.
class _PendingWithdrawals extends ConsumerWidget {
  const _PendingWithdrawals();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(pixPendingWithdrawalsProvider);
    final content = records.isEmpty
        ? const SizedBox(key: ValueKey('none'), width: double.infinity)
        : _PendingWithdrawalList(key: const ValueKey('list'), records: records);

    return SizeFadeSwitcher(child: content);
  }
}

class _PendingWithdrawalList extends ConsumerWidget {
  final List<PixWithdrawalRecord> records;

  const _PendingWithdrawalList({super.key, required this.records});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: _sectionGap),
        PixSectionHeader(title: t.pix_hub_pending_withdrawals_title),
        const SizedBox(height: _sectionTitleGap),
        PixOperationList(
          items: [
            for (final record in records)
              PixOperationItem(
                // The hourglass marks a payment without a final status.
                icon: PixIcons.pending,
                label: t.pix_hub_pending_withdrawal_item(
                  formatBrlCents(record.payoutAmountInCents),
                  record.maskedKey,
                ),
                onTap: () {
                  ref.read(pixSendControllerProvider.notifier).resume(record);
                  context.push('/pix/send/result');
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          t.pix_hub_pending_withdrawal_hint,
          // Secondary, not tertiary: the tertiary gray fails 4.5:1 on the
          // light page background.
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// The five Pix operations reachable from the hub.
class _OtherOperations extends StatelessWidget {
  final void Function(String route) onSend;

  const _OtherOperations({required this.onSend});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return PixOperationList(
      items: [
        PixOperationItem(
          icon: PixIcons.key,
          label: t.pix_hub_action_pay_key,
          onTap: () => onSend('/pix/send/key'),
        ),
        PixOperationItem(
          icon: PixIcons.scan,
          label: t.pix_hub_action_pay_qr,
          onTap: () => onSend('/pix/send/scan'),
        ),
        PixOperationItem(
          icon: PixIcons.copy,
          label: t.pix_hub_action_copy_paste,
          onTap: () => onSend('/pix/send/code'),
        ),
        PixOperationItem(
          icon: PixIcons.link,
          label: t.pix_hub_action_links,
          onTap: () => context.push('/pix/links'),
        ),
        PixOperationItem(
          icon: PixIcons.history,
          label: t.pix_hub_action_history,
          onTap: () => context.push('/pix/history'),
        ),
      ],
    );
  }
}

/// Limits and level, both served by the screens that already exist.
class _Preferences extends StatelessWidget {
  const _Preferences();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return PixOperationList(
      items: [
        PixOperationItem(
          icon: PixIcons.shieldCheck,
          label: t.pix_hub_preferences_limits,
          onTap: () => context.push('/pix/limits'),
        ),
        PixOperationItem(
          icon: PixIcons.star,
          label: t.pix_hub_preferences_level,
          onTap: () => context.push('/wallet-levels'),
        ),
      ],
    );
  }
}
