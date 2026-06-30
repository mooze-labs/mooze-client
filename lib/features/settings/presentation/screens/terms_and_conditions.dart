import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_expandable_section.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_footer_link.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_header.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_info_card.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_section.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_warning_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  late final List<bool> _expandedSections;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _expandedSections = List<bool>.filled(32, false);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final shouldShow = _scrollController.offset >= 200;
    if (shouldShow != _showBackToTop) {
      setState(() => _showBackToTop = shouldShow);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _launchUrl(String url) async {
    final t = AppLocalizations.of(context);
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback && mounted) {
          AppSnackBar.error(context, t.error_open_link);
        }
      }
    } catch (_) {
      if (mounted) AppSnackBar.error(context, t.error_opening_link);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sections = _buildTermsSections(t);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.terms_title),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LegalDocumentHeader(
                    icon: Icons.gavel_rounded,
                    title: t.terms_title,
                    subtitle: t.terms_subtitle,
                    description: t.terms_intro,
                  ),
                  const SizedBox(height: 24),
                  LegalDocumentWarningCard(
                    icon: Icons.warning_amber_rounded,
                    title: t.terms_warning_title,
                    message: t.terms_warning_message,
                    containerColor: colorScheme.errorContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderColor: colorScheme.error.withValues(alpha: 0.3),
                    iconColor: colorScheme.error,
                    textColor: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(height: 24),
                  _buildQuickInfo(t),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return LegalDocumentExpandableSection(
                index: index,
                section: sections[index],
                isExpanded: _expandedSections[index],
                onExpansionChanged: (expanded) {
                  setState(() => _expandedSections[index] = expanded);
                },
              );
            }, childCount: sections.length),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 32),
                _buildFooter(colorScheme, textTheme, t),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          _showBackToTop
              ? FloatingActionButton.small(
                onPressed: _scrollToTop,
                elevation: 4,
                child: const Icon(Icons.keyboard_arrow_up_rounded),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildQuickInfo(AppLocalizations t) {
    return SizedBox(
      height: 125,
      child: Row(
        children: [
          Expanded(
            child: LegalDocumentInfoCard(
              icon: Icons.account_balance_rounded,
              title: t.terms_self_custody_title,
              subtitle: t.terms_self_custody_subtitle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LegalDocumentInfoCard(
              icon: Icons.shield_rounded,
              title: t.terms_privacy_title,
              subtitle: t.terms_privacy_subtitle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LegalDocumentInfoCard(
              icon: Icons.science_rounded,
              title: t.terms_beta_title,
              subtitle: t.terms_beta_subtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations t,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.update_rounded,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                t.terms_last_updated,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LegalDocumentFooterLink(
            icon: Icons.privacy_tip_outlined,
            label: t.terms_privacy_policy_link,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.primary,
            onTap: () => _launchUrl('https://mooze.app/termos-e-privacidade/'),
          ),
        ],
      ),
    );
  }
}

List<LegalDocumentSection> _buildTermsSections(AppLocalizations t) {
  return [
    LegalDocumentSection(t.terms_section_1, t.terms_section_1_body),
    LegalDocumentSection(t.terms_section_2, t.terms_section_2_body),
    LegalDocumentSection(t.terms_section_3, t.terms_section_3_body),
    LegalDocumentSection(t.terms_section_4, t.terms_section_4_body),
    LegalDocumentSection(t.terms_section_5, t.terms_section_5_body),
    LegalDocumentSection(t.terms_section_6, t.terms_section_6_body),
    LegalDocumentSection(t.terms_section_7, t.terms_section_7_body),
    LegalDocumentSection(t.terms_section_8, t.terms_section_8_body),
    LegalDocumentSection(t.terms_section_9, t.terms_section_9_body),
    LegalDocumentSection(t.terms_section_10, t.terms_section_10_body),
    LegalDocumentSection(t.terms_section_11, t.terms_section_11_body),
    LegalDocumentSection(t.terms_section_12, t.terms_section_12_body),
    LegalDocumentSection(t.terms_section_13, t.terms_section_13_body),
    LegalDocumentSection(t.terms_section_14, t.terms_section_14_body),
    LegalDocumentSection(t.terms_section_15, t.terms_section_15_body),
    LegalDocumentSection(t.terms_section_16, t.terms_section_16_body),
    LegalDocumentSection(t.terms_section_17, t.terms_section_17_body),
    LegalDocumentSection(t.terms_section_18, t.terms_section_18_body),
    LegalDocumentSection(t.terms_section_19, t.terms_section_19_body),
    LegalDocumentSection(
      t.privacy_section_header,
      t.privacy_section_header_body,
    ),
    LegalDocumentSection(t.privacy_section_1, t.privacy_section_1_body),
    LegalDocumentSection(t.privacy_section_2, t.privacy_section_2_body),
    LegalDocumentSection(t.privacy_section_3, t.privacy_section_3_body),
    LegalDocumentSection(t.privacy_section_4, t.privacy_section_4_body),
    LegalDocumentSection(t.privacy_section_5, t.privacy_section_5_body),
    LegalDocumentSection(t.privacy_section_6, t.privacy_section_6_body),
    LegalDocumentSection(t.privacy_section_7, t.privacy_section_7_body),
    LegalDocumentSection(t.privacy_section_8, t.privacy_section_8_body),
    LegalDocumentSection(t.privacy_section_9, t.privacy_section_9_body),
    LegalDocumentSection(t.privacy_section_10, t.privacy_section_10_body),
    LegalDocumentSection(t.privacy_section_11, t.privacy_section_11_body),
    LegalDocumentSection(t.privacy_section_12, t.privacy_section_12_body),
  ];
}
