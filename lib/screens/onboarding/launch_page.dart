import 'package:flutter/material.dart';

import 'package:dab_fitness/config/onboarding_strings.dart';
import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/screens/onboarding/welcome_page.dart';

/// First-run onboarding: four slides, then the Welcome page.
class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _Slide {
  final String image;
  final String title;
  final String body;
  const _Slide(this.image, this.title, this.body);
}

class _LaunchPageState extends State<LaunchPage> {
  static const _slides = [
    _Slide('assets/images/launch-4.png', OnboardingStrings.stepOneTitle,
        OnboardingStrings.stepOneContent),
    _Slide('assets/images/launch-1.png', OnboardingStrings.stepTwoTitle,
        OnboardingStrings.stepTwoContent),
    _Slide('assets/images/launch-3.jpg', OnboardingStrings.stepThreeTitle,
        OnboardingStrings.stepThreeContent),
    _Slide('assets/images/launch-2.jpg', OnboardingStrings.stepFourContent,
        OnboardingStrings.stepFourBody),
  ];

  final _pageController = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() =>
      Navigator.of(context).pushReplacementNamed(WelcomePage.routeName);

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(_slides[i]),
              ),
            ),
            _Dots(count: _slides.length, index: _index),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.xl, AppSpacing.screen, AppSpacing.lg),
              child: Row(
                children: [
                  // Keep the layout stable on the last slide.
                  Visibility(
                    visible: !_isLast,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(
                        onPressed: _finish, child: const Text('Skip')),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_isLast ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView(this.slide);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.appColors.illustration,
                borderRadius: AppRadius.cardAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Image.asset(slide.image,
                      fit: BoxFit.contain, excludeFromSemantics: true),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, AppSpacing.xl, AppSpacing.screen, 0),
            child: Column(
              children: [
                Text(slide.title,
                    textAlign: TextAlign.center,
                    style: context.textStyles.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Text(slide.body,
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodyLarge
                        ?.copyWith(color: context.appColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${index + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              height: AppSpacing.sm,
              width: i == index ? AppSpacing.xl : AppSpacing.sm,
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color: i == index
                    ? context.colors.primary
                    : context.appColors.divider,
              ),
            ),
        ],
      ),
    );
  }
}
