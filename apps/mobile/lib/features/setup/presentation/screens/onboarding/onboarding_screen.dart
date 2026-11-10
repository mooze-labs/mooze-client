import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/data/onboarding/onboarding_data.dart';
import 'package:mooze_mobile/features/setup/presentation/providers/onboarding_provider.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/onboarding/widgets/onboarding_scene.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The first screens of a new install: four pages about the wallet, Pix,
/// swaps, and security, before the choice to create or import a wallet.
///
/// Each page has its art at the top, see [OnboardingSceneView], and its
/// text below. The art enters the first time its page shows, drifts for a
/// few seconds, and rests; as the pages slide, it moves slower than the
/// text and turns with the finger. Under reduced motion the art stays
/// still.
///
/// "Skip" and the button of the last page mark the onboarding as done and
/// open the first access screen, or run [onDone] instead.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.onDone});

  /// Runs instead of the end of the onboarding, for example to close a
  /// preview.
  final VoidCallback? onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  /// Side margin of the content.
  static const double _gutter = 24;

  final PageController _pageController = PageController();

  /// One clock per page, from the first time it shows. A page shown again
  /// keeps its art at rest.
  late final List<AnimationController> _clocks = [
    for (final _ in OnboardingScene.values)
      AnimationController(vsync: this, duration: Motion.durationAmbient * 2),
  ];

  int _currentIndex = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play(0);
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final clock in _clocks) {
      clock.dispose();
    }
    super.dispose();
  }

  void _play(int index) {
    final clock = _clocks[index];
    if (!clock.isDismissed) return;
    if (Motion.isReduced(context)) {
      clock.value = 1;
    } else {
      clock.forward();
    }
  }

  /// Plays the art of a page as soon as a third of it shows, so it enters
  /// while the finger still slides it in, before the page counts as
  /// changed at half.
  void _onScroll() {
    final page = _pageController.page;
    if (page == null) return;
    for (final index in {page.floor(), page.ceil()}) {
      if ((index - page).abs() <= 2 / 3) _play(index);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _play(index);
  }

  void _handleNextPage() {
    if (_currentIndex == _clocks.length - 1) {
      _finish();
    } else if (Motion.isReduced(context)) {
      _pageController.jumpToPage(_currentIndex + 1);
    } else {
      _pageController.nextPage(
        duration: Motion.durationSlow,
        curve: Motion.curveLargeMove,
      );
    }
  }

  Future<void> _finish() async {
    final onDone = widget.onDone;
    if (onDone != null) {
      onDone();
      return;
    }
    await ref.read(onboardingServiceProvider).setOnboardingCompleted();
    if (mounted) context.go('/setup/first-access');
  }

  /// Where the page of [index] is from the center of the screen.
  double _offsetOf(int index) {
    final position = _pageController.hasClients
        ? _pageController.position
        : null;
    final page = position != null && position.haveDimensions
        ? _pageController.page!
        : _currentIndex.toDouble();
    return (index - page).clamp(-1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pages = OnboardingPageData.items(t);
    final isLast = _currentIndex == pages.length - 1;
    final still = Motion.isReduced(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: Column(
              children: [
                _Header(
                  skipLabel: t.onboarding_skip,
                  showSkip: !isLast,
                  onSkip: _finish,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) => _OnboardingPage(
                      pages: pages,
                      index: index,
                      art: AnimatedBuilder(
                        animation: Listenable.merge([
                          _pageController,
                          _clocks[index],
                        ]),
                        builder: (context, _) {
                          final offset = still ? 0.0 : _offsetOf(index);
                          return _Parallax(
                            offset: offset,
                            child: OnboardingSceneView(
                              scene: pages[index].scene,
                              motion: SceneMotion(
                                time: _clocks[index].value,
                                offset: offset,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: _PageDots(
                    controller: _pageController,
                    count: pages.length,
                    currentIndex: _currentIndex,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(_gutter, 0, _gutter, 12),
                  child: PrimaryButton(
                    text: isLast ? t.onboarding_get_started : t.common_next,
                    onPressed: _handleNextPage,
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

/// The logo, and "Skip" until the last page.
class _Header extends StatelessWidget {
  const _Header({
    required this.skipLabel,
    required this.showSkip,
    required this.onSkip,
  });

  final String skipLabel;
  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/logos/logo_primary.svg',
              height: 22,
              colorFilter: ColorFilter.mode(
                context.colors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
            const Spacer(),
            AnimatedOpacity(
              opacity: showSkip ? 1 : 0,
              duration: Motion.of(context, Motion.durationFast),
              curve: Motion.curveMove,
              child: IgnorePointer(
                ignoring: !showSkip,
                child: ExcludeSemantics(
                  excluding: !showSkip,
                  child: TextButton(
                    onPressed: onSkip,
                    child: Text(
                      skipLabel,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The page of [index]: its [art] on top, its text below.
///
/// The text takes the height of the longest text of all [pages], so the
/// art has the same room on every page and does not jump as the pages
/// slide.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.pages,
    required this.index,
    required this.art,
  });

  final List<OnboardingPageData> pages;
  final int index;
  final Widget art;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: art,
            ),
          ),
          ConstrainedBox(
            // With large text the text scrolls, and the art keeps a third
            // of the page.
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight * 2 / 3,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: IndexedStack(
                index: index,
                children: [for (final page in pages) _PageText(page)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The eyebrow, the title with its highlight in the brand color, and the
/// body of a page.
class _PageText extends StatelessWidget {
  const _PageText(this.data);

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final title = data.title;
    final start = title.indexOf(data.highlight);
    final brand = TextStyle(color: context.colors.primaryColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          data.eyebrow,
          textAlign: TextAlign.center,
          style: context.textTheme.labelMedium?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text.rich(
            start < 0
                ? TextSpan(text: title)
                : TextSpan(
                    children: [
                      TextSpan(text: title.substring(0, start)),
                      TextSpan(text: data.highlight, style: brand),
                      TextSpan(
                        text: title.substring(start + data.highlight.length),
                      ),
                    ],
                  ),
            textAlign: TextAlign.center,
            style: context.textTheme.headlineMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          data.body,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// The art of a page at its [offset] from the center: it moves slower than
/// the page and fades as it leaves, so the arts of two pages cross-fade.
class _Parallax extends StatelessWidget {
  const _Parallax({required this.offset, required this.child});

  final double offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Opacity(
        opacity: 1 - offset.abs(),
        child: Transform.translate(
          offset: Offset(-offset * constraints.maxWidth * 0.35, 0),
          child: child,
        ),
      ),
    );
  }
}

/// One dot per page. The dot of the page in view stretches, following the
/// finger as the pages slide.
class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.controller,
    required this.count,
    required this.currentIndex,
  });

  final PageController controller;
  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final brand = context.colors.primaryColor;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final page =
              controller.hasClients && controller.position.haveDimensions
              ? controller.page!
              : currentIndex.toDouble();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < count; i++)
                Builder(
                  builder: (context) {
                    final shown = (1 - (page - i).abs()).clamp(0.0, 1.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: lerpDouble(8, 24, shown),
                      decoration: BoxDecoration(
                        color: brand.withValues(
                          alpha: lerpDouble(0.3, 1, shown),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
