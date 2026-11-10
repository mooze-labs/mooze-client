import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// The art at the top of an onboarding page.
enum OnboardingScene {
  /// The four asset coins orbit the Mooze coin.
  wallet,

  /// A beam of light carries a Pix payment to a Bitcoin coin.
  pix,

  /// Two coins swap places on an orbit, inside two crossing rings.
  swap,

  /// A vault medal with a padlock, among the blurred recovery words.
  security,
}

class OnboardingPageData {
  final OnboardingScene scene;
  final String eyebrow;
  final String title;

  /// The part of [title] in the brand color.
  final String highlight;
  final String body;

  const OnboardingPageData({
    required this.scene,
    required this.eyebrow,
    required this.title,
    required this.highlight,
    required this.body,
  });

  /// Returns the localized list of onboarding pages.
  ///
  /// We avoid a top-level `const` list because the strings come from
  /// `AppLocalizations`, which requires a `BuildContext` to resolve.
  static List<OnboardingPageData> items(AppLocalizations t) => [
    OnboardingPageData(
      scene: OnboardingScene.wallet,
      eyebrow: t.onboarding_1_eyebrow,
      title: t.onboarding_1_title,
      highlight: t.onboarding_1_highlight,
      body: t.onboarding_1_body,
    ),
    OnboardingPageData(
      scene: OnboardingScene.pix,
      eyebrow: t.onboarding_2_eyebrow,
      title: t.onboarding_2_title,
      highlight: t.onboarding_2_highlight,
      body: t.onboarding_2_body,
    ),
    OnboardingPageData(
      scene: OnboardingScene.swap,
      eyebrow: t.onboarding_3_eyebrow,
      title: t.onboarding_3_title,
      highlight: t.onboarding_3_highlight,
      body: t.onboarding_3_body,
    ),
    OnboardingPageData(
      scene: OnboardingScene.security,
      eyebrow: t.onboarding_4_eyebrow,
      title: t.onboarding_4_title,
      highlight: t.onboarding_4_highlight,
      body: t.onboarding_4_body,
    ),
  ];
}
