import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';

enum LegalDocument { privacyPolicy, termsOfUse }

class LegalScreen extends StatefulWidget {
  const LegalScreen({
    this.initialDocument = LegalDocument.privacyPolicy,
    super.key,
  });

  final LegalDocument initialDocument;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  static const _privacyPolicyUrl = String.fromEnvironment(
    'MASSLENS_PRIVACY_URL',
  );

  late LegalDocument _document = widget.initialDocument;

  Future<void> _openPublishedPolicy() async {
    final l10n = context.l10n;
    final uri = Uri.tryParse(_privacyPolicyUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsPrivacyPolicyUnavailable)),
      );
      return;
    }

    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      // A missing platform URL handler is reported with the message below.
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsPrivacyPolicyOpenFailed)),
      );
    }
  }

  List<_LegalSection> _privacySections(AppLocalizations l10n) => [
    _LegalSection(
      title: l10n.legalPrivacyScopeTitle,
      body: l10n.legalPrivacyScopeBody,
    ),
    _LegalSection(
      title: l10n.legalPrivacyPhotosTitle,
      body: l10n.legalPrivacyPhotosBody,
    ),
    _LegalSection(
      title: l10n.legalPrivacyNutritionTitle,
      body: l10n.legalPrivacyNutritionBody,
    ),
    _LegalSection(
      title: l10n.legalPrivacyLocalTitle,
      body: l10n.legalPrivacyLocalBody,
    ),
    _LegalSection(
      title: l10n.legalPrivacyServiceTitle,
      body: l10n.legalPrivacyServiceBody,
    ),
    _LegalSection(
      title: l10n.legalPrivacyAdsTitle,
      body: l10n.legalPrivacyAdsBody,
    ),
    _LegalSection(
      title: l10n.legalPrivacySharingTitle,
      body: l10n.legalPrivacySharingBody,
    ),
    _LegalSection(
      title: l10n.legalPrivacyChoicesTitle,
      body: l10n.legalPrivacyChoicesBody,
    ),
    _LegalSection(
      title: l10n.legalPrivacySecurityTitle,
      body: l10n.legalPrivacySecurityBody,
    ),
    _LegalSection(
      title: l10n.legalPrivacyChangesTitle,
      body: l10n.legalPrivacyChangesBody,
    ),
  ];

  List<_LegalSection> _termsSections(AppLocalizations l10n) => [
    _LegalSection(
      title: l10n.legalTermsAcceptanceTitle,
      body: l10n.legalTermsAcceptanceBody,
    ),
    _LegalSection(
      title: l10n.legalTermsServiceTitle,
      body: l10n.legalTermsServiceBody,
    ),
    _LegalSection(
      title: l10n.legalTermsEstimatesTitle,
      body: l10n.legalTermsEstimatesBody,
    ),
    _LegalSection(
      title: l10n.legalTermsContentTitle,
      body: l10n.legalTermsContentBody,
    ),
    _LegalSection(
      title: l10n.legalTermsCreditsTitle,
      body: l10n.legalTermsCreditsBody,
    ),
    _LegalSection(
      title: l10n.legalTermsThirdPartyTitle,
      body: l10n.legalTermsThirdPartyBody,
    ),
    _LegalSection(
      title: l10n.legalTermsLicenseTitle,
      body: l10n.legalTermsLicenseBody,
    ),
    _LegalSection(
      title: l10n.legalTermsAvailabilityTitle,
      body: l10n.legalTermsAvailabilityBody,
    ),
    _LegalSection(
      title: l10n.legalTermsLiabilityTitle,
      body: l10n.legalTermsLiabilityBody,
    ),
    _LegalSection(
      title: l10n.legalTermsChangesTitle,
      body: l10n.legalTermsChangesBody,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final privacySelected = _document == LegalDocument.privacyPolicy;
    final sections = privacySelected
        ? _privacySections(l10n)
        : _termsSections(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.legalTitle)),
      body: SafeArea(
        top: false,
        child: SelectionArea(
          child: ListView(
            key: const Key('legal_document_scroll'),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.gavel_rounded,
                      color: AppColors.aqua,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.legalIntroTitle,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.legalIntroBody,
                            style: const TextStyle(
                              color: Color(0xFFD7E0E4),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SegmentedButton<LegalDocument>(
                key: const Key('legal_document_selector'),
                expandedInsets: EdgeInsets.zero,
                segments: [
                  ButtonSegment(
                    value: LegalDocument.privacyPolicy,
                    icon: const Icon(Icons.shield_outlined),
                    label: Text(l10n.legalPrivacyPolicy),
                  ),
                  ButtonSegment(
                    value: LegalDocument.termsOfUse,
                    icon: const Icon(Icons.description_outlined),
                    label: Text(l10n.legalTermsOfUse),
                  ),
                ],
                selected: {_document},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  setState(() => _document = selection.single);
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      privacySelected
                          ? l10n.legalPrivacyPolicy
                          : l10n.legalTermsOfUse,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      l10n.legalLastUpdated,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Column(
                  key: ValueKey(_document),
                  children: [
                    for (var index = 0; index < sections.length; index++) ...[
                      _LegalSectionCard(
                        index: index + 1,
                        section: sections[index],
                      ),
                      if (index != sections.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              if (privacySelected) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  key: const Key('open_published_privacy_policy'),
                  onPressed: _openPublishedPolicy,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(l10n.legalPublishedPolicy),
                ),
              ],
              const SizedBox(height: 18),
              Center(
                child: Text(
                  l10n.legalFooter,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({required this.index, required this.section});

  final int index;
  final _LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0x3358D6C7),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            section.body,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontSize: 13,
              height: 1.58,
            ),
          ),
        ],
      ),
    );
  }
}
