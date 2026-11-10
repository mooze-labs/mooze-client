import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_back_to_top_button.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_expandable_section.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_footer_link.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_header.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_info_card.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_section.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_warning_card.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_glass_section.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_page_scaffold.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
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
    _expandedSections = List<bool>.filled(33, false);
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
    final sections = _buildTermsSections(t);

    return SettingsPageScaffold(
      title: t.terms_title,
      floatingActionButton: _showBackToTop
          ? LegalDocumentBackToTopButton(onPressed: _scrollToTop)
          : null,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SettingsPageScaffold.gutter,
                12,
                SettingsPageScaffold.gutter,
                0,
              ),
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
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildQuickInfo(t)),
          SliverToBoxAdapter(
            child: SettingsGlassSection(
              child: Column(
                children: [
                  for (var index = 0; index < sections.length; index++) ...[
                    if (index > 0) const PanelDivider(indent: 56),
                    LegalDocumentExpandableSection(
                      index: index,
                      section: sections[index],
                      isExpanded: _expandedSections[index],
                      onExpansionChanged: (expanded) {
                        setState(() => _expandedSections[index] = expanded);
                      },
                      // The unnumbered preamble keeps section numbers aligned
                      // with their clause numbers.
                      showInfoIconForFirst: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildFooter(t),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(AppLocalizations t) {
    return SettingsGlassSection(
      child: Column(
        children: [
          LegalDocumentInfoCard(
            icon: Icons.account_balance_rounded,
            title: t.terms_self_custody_title,
            subtitle: t.terms_self_custody_subtitle,
          ),
          const PanelDivider(indent: 48),
          LegalDocumentInfoCard(
            icon: Icons.shield_rounded,
            title: t.terms_privacy_title,
            subtitle: t.terms_privacy_subtitle,
          ),
          const PanelDivider(indent: 48),
          LegalDocumentInfoCard(
            icon: Icons.science_rounded,
            title: t.terms_beta_title,
            subtitle: t.terms_beta_subtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations t) {
    final colors = context.colors;

    return Column(
      children: [
        SettingsGlassSection(
          child: LegalDocumentFooterLink(
            icon: Icons.privacy_tip_outlined,
            label: t.terms_privacy_policy_link,
            onTap: () => _launchUrl('https://mooze.app/termos-e-privacidade/'),
          ),
        ),
        const SizedBox(height: 20),
        LiquidGlass(
          blurBackdrop: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.update_rounded,
                  size: 14,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  t.terms_last_updated,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

List<LegalDocumentSection> _buildTermsSections(AppLocalizations t) {
  return [
    LegalDocumentSection(t.terms_preamble, t.terms_preamble_body),
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
