import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

class OnboardingPageData {
  final String title;
  final String subtitle;

  const OnboardingPageData({required this.title, required this.subtitle});

  /// Returns the localized list of onboarding pages.
  ///
  /// We avoid a top-level `const` list because the strings come from
  /// `AppLocalizations`, which requires a `BuildContext` to resolve.
  static List<OnboardingPageData> items(AppLocalizations t) => [
    OnboardingPageData(
      title: t.onboarding_1_title,
      subtitle: t.onboarding_1_body,
    ),
    OnboardingPageData(
      title: t.onboarding_2_title,
      subtitle: t.onboarding_2_body,
    ),
    OnboardingPageData(
      title: t.onboarding_3_title,
      subtitle: t.onboarding_3_body,
    ),
  ];
}
