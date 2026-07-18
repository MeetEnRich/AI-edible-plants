import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: _controller,
          onPageChanged: (index) {
            setState(() => isLastPage = index == 2);
          },
          children: [
            _buildPage(
              imagePath: 'assets/onboarding_1.png',
              title: 'Identify Safely',
              subtitle: 'Scan any leaf or plant with our advanced Gemini AI. It acts as your personal ethnobotanist, explaining exactly why a plant is identified as edible or toxic.',
            ),
            _buildPage(
              imagePath: 'assets/onboarding_2.png',
              title: 'Works Offline',
              subtitle: 'Foraging in remote areas? Our robust offline database saves your scans immediately and seamlessly syncs them to the cloud when you return to civilization.',
            ),
            _buildPage(
              imagePath: 'assets/onboarding_3.png',
              title: 'Preserve Knowledge',
              subtitle: 'Access a rich encyclopedia of indigenous Nigerian plants, complete with local names (Igbo, Hausa, Yoruba) and traditional preparation methods.',
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => _controller.jumpToPage(2),
              child: Text(
                'SKIP',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ),
            SmoothPageIndicator(
              controller: _controller,
              count: 3,
              effect: ExpandingDotsEffect(
                activeDotColor: AppColors.primary,
                dotColor: AppColors.primary.withValues(alpha: 0.2),
                dotHeight: 8,
                dotWidth: 8,
                spacing: 8,
              ),
            ),
            isLastPage
                ? TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'START',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
                    child: Text(
                      'NEXT',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String imagePath,
    required String title,
    required String subtitle,
  }) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 28,
              color: AppColors.primaryDark,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
