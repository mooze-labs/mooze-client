import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/setup/data/onboarding/onboarding_data.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Controllers
  final PageController _pageController = PageController();

  // State
  int _currentIndex = 0;

  // Constants
  static const Duration _pageAnimationDuration = Duration(milliseconds: 400);
  static const Duration _indicatorAnimationDuration = Duration(
    milliseconds: 300,
  );
  static const double _logoHeight = 33.0;
  static const double _mockupHeight = 300.0;
  static const double _indicatorActiveWidth = 24.0;
  static const double _indicatorInactiveSize = 8.0;
  static const double _horizontalPadding = 24.0;
  static const List<OnboardingPageData> _pages = OnboardingPageData.pages;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleNextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: _pageAnimationDuration,
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToNextScreen();
    }
  }

  void _handleSkip() {
    _navigateToNextScreen();
  }

  // TODO: Add navigation route
  void _navigateToNextScreen() {
    Navigator.pushReplacementNamed(context, '/');
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String get _buttonText {
    return _currentIndex == _pages.length - 1 ? 'Começar' : 'Próximo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [_buildHeader(), _buildPageView(), _buildBottomSection()],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SvgPicture.asset(
        'assets/logos/logo_primary.svg',
        height: _logoHeight,
      ),
    );
  }

  Widget _buildPageView() {
    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return _buildOnboardingPage(_pages[index]);
        },
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPageData pageData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Column(
        children: [
          const SizedBox(height: 60),
          _buildMockupContainer(),
          const SizedBox(height: 32),
          _buildPageIndicator(),
          const SizedBox(height: 24),
          _buildPageTitle(pageData.title),
          const SizedBox(height: 16),
          _buildPageSubtitle(pageData.subtitle),
        ],
      ),
    );
  }

  /// (placeholder for images/illustrations)
  Widget _buildMockupContainer() {
    return Container(
      height: _mockupHeight,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      // TODO: Add specific illustrations for each page.
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        return _buildIndicatorDot(index);
      }),
    );
  }

  Widget _buildIndicatorDot(int index) {
    final isActive = index == _currentIndex;
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: _indicatorAnimationDuration,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: _indicatorInactiveSize,
      width: isActive ? _indicatorActiveWidth : _indicatorInactiveSize,
      decoration: BoxDecoration(
        color: isActive ? primaryColor : primaryColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildPageTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPageSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildPrimaryButton(),
        _buildSkipButton(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: PrimaryButton(text: _buttonText, onPressed: _handleNextPage),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _handleSkip,
      child: Text(
        'Pular',
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
