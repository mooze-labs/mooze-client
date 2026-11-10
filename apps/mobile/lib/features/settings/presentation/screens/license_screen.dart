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
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:url_launcher/url_launcher.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  late final List<bool> _expandedSections;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _expandedSections = List<bool>.filled(19, false);
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
    final colors = context.colors;
    final textTheme = context.textTheme;
    final sections = _buildLicenseSections(t);

    return SettingsPageScaffold(
      title: t.license_title,
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
                    icon: Icons.description_rounded,
                    title: t.license_title,
                    subtitle: t.license_subtitle,
                    description: t.license_version_line,
                  ),
                  const SizedBox(height: 24),
                  LegalDocumentWarningCard(
                    icon: Icons.info_outline_rounded,
                    title: t.license_copyleft_title,
                    message: t.license_copyleft_desc,
                    iconColor: colors.textSecondary,
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
                      showInfoIconForFirst: true,
                      useMonospaceContent: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SettingsPageScaffold.gutter,
                  ),
                  child: Text(
                    t.license_end_terms,
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
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
            icon: Icons.lock_open_rounded,
            title: t.license_free_software_title,
            subtitle: t.license_free_software_subtitle,
          ),
          const PanelDivider(indent: 48),
          LegalDocumentInfoCard(
            icon: Icons.share_rounded,
            title: t.license_redistributable_title,
            subtitle: t.license_redistributable_subtitle,
          ),
          const PanelDivider(indent: 48),
          LegalDocumentInfoCard(
            icon: Icons.code_rounded,
            title: t.license_copyleft_short_title,
            subtitle: t.license_copyleft_short_subtitle,
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
          child: Column(
            children: [
              LegalDocumentFooterLink(
                icon: Icons.public_rounded,
                label: t.license_fsf_link,
                onTap: () => _launchUrl('https://www.fsf.org/'),
              ),
              const PanelDivider(indent: 48),
              LegalDocumentFooterLink(
                icon: Icons.article_outlined,
                label: t.license_full_link,
                onTap: () =>
                    _launchUrl('https://www.gnu.org/licenses/gpl-3.0.html'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SettingsPageScaffold.gutter,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.copyright_rounded,
                size: 14,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  t.license_copyright_line,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

List<LegalDocumentSection> _buildLicenseSections(AppLocalizations t) {
  return [
    LegalDocumentSection(
      t.license_section_preamble,
      t.license_section_preamble_body,
    ),
    LegalDocumentSection(
      t.license_section_definitions,
      t.license_section_definitions_body,
    ),
    LegalDocumentSection(
      t.license_section_source,
      t.license_section_source_body,
    ),
    LegalDocumentSection(
      t.license_section_basic_perms,
      t.license_section_basic_perms_body,
    ),
    LegalDocumentSection(
      t.license_section_legal_rights,
      t.license_section_legal_rights_body,
    ),
    LegalDocumentSection(
      t.license_section_verbatim,
      t.license_section_verbatim_body,
    ),
    LegalDocumentSection(
      t.license_section_modified,
      t.license_section_modified_body,
    ),
    LegalDocumentSection(
      t.license_section_non_source,
      t.license_section_non_source_body,
    ),
    LegalDocumentSection(
      t.license_section_additional,
      t.license_section_additional_body,
    ),
    LegalDocumentSection(
      t.license_section_termination,
      t.license_section_termination_body,
    ),
    LegalDocumentSection(
      t.license_section_acceptance,
      t.license_section_acceptance_body,
    ),
    LegalDocumentSection(
      t.license_section_downstream,
      t.license_section_downstream_body,
    ),
    LegalDocumentSection(
      t.license_section_patents,
      t.license_section_patents_body,
    ),
    LegalDocumentSection(
      t.license_section_no_surrender,
      t.license_section_no_surrender_body,
    ),
    LegalDocumentSection(t.license_section_agpl, t.license_section_agpl_body),
    LegalDocumentSection(
      t.license_section_revisions,
      t.license_section_revisions_body,
    ),
    LegalDocumentSection(
      t.license_section_warranty,
      t.license_section_warranty_body,
    ),
    LegalDocumentSection(
      t.license_section_liability,
      t.license_section_liability_body,
    ),
    LegalDocumentSection(
      t.license_section_interpretation,
      t.license_section_interpretation_body,
    ),
  ];
}
