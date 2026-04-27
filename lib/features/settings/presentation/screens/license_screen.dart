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
    final colorScheme = Theme.of(context).colorScheme;
    final sections = _buildLicenseSections(t);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.license_title),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: t.common_back,
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
                    icon: Icons.description_rounded,
                    title: t.license_title,
                    subtitle: t.license_subtitle,
                    description: t.license_version_line,
                  ),
                  const SizedBox(height: 24),
                  LegalDocumentWarningCard(
                    icon: Icons.info_rounded,
                    title: t.license_copyleft_title,
                    message: t.license_copyleft_desc,
                    containerColor: colorScheme.tertiaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderColor: colorScheme.tertiary.withValues(alpha: 0.3),
                    iconColor: colorScheme.tertiary,
                    textColor: colorScheme.onTertiaryContainer,
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
                showInfoIconForFirst: true,
                useMonospaceContent: true,
              );
            }, childCount: sections.length),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Center(child: Text(t.license_end_terms)),
                const SizedBox(height: 16),
                _buildFooter(colorScheme, t),
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
              icon: Icons.lock_open_rounded,
              title: t.license_free_software_title,
              subtitle: t.license_free_software_subtitle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LegalDocumentInfoCard(
              icon: Icons.share_rounded,
              title: t.license_redistributable_title,
              subtitle: t.license_redistributable_subtitle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LegalDocumentInfoCard(
              icon: Icons.code_rounded,
              title: t.license_copyleft_short_title,
              subtitle: t.license_copyleft_short_subtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme, AppLocalizations t) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.copyright_rounded,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.license_copyright_line,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LegalDocumentFooterLink(
                icon: Icons.public_rounded,
                label: t.license_fsf_link,
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                onTap: () => _launchUrl('https://www.fsf.org/'),
              ),
              const SizedBox(height: 8),
              LegalDocumentFooterLink(
                icon: Icons.article_outlined,
                label: t.license_full_link,
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                onTap:
                    () =>
                        _launchUrl('https://www.gnu.org/licenses/gpl-3.0.html'),
              ),
            ],
          ),
        ],
      ),
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
