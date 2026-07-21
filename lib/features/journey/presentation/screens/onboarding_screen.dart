import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  /// When true, shows "Close" on the last page instead of "Get Started"
  /// and doesn't navigate to auth.
  final bool isHelpMode;

  const OnboardingScreen({super.key, this.isHelpMode = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.home_rounded,
      gradientColors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      title: 'Today',
      subtitle: 'Your Daily Mission Control',
      points: [
          'See all your active missions for today at a glance.',
          'Complete tasks, earn XP, level up, and build powerful daily streaks.',
          'Every mission accomplished brings you closer to your goals.',
      ],
    ),
    _OnboardingPageData(
      icon: Icons.calendar_view_week_rounded,
      gradientColors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      title: 'Planner',
      subtitle: 'Strategize Your Week',
      points: [
          'Plan missions across the entire week with smart repetition.',
          'Set priorities, schedule reminders, and intelligently rotate your focus.',
          'Nothing falls through the cracks.',
      ],
    ),
    _OnboardingPageData(
      icon: Icons.show_chart_rounded,
      gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
      title: 'Progress',
      subtitle: 'Track Your Growth',
      points: [
          'Watch your XP climb with an exponential leveling system.',
          'Track streaks, unlock badges, and manage active projects.',
          'Visualize your weekly activity at a glance.',
      ],
    ),
    _OnboardingPageData(
      icon: Icons.person_rounded,
      gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      title: 'Profile',
      subtitle: 'Your Identity & Bio',
      points: [
          'Customize your name, role, motto, and bio.',
          'Your profile is your personal brand within Ascent.',
          'Make it reflect who you are and who you want to become.',
      ],
    ),
  ];

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _onGetStarted() async {
    if (widget.isHelpMode) {
      Navigator.of(context).pop();
    } else {
      await ref.read(onboardingNotifierProvider.notifier).completeOnboarding();
      if (mounted) context.go('/auth');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (top-right)
            if (!widget.isHelpMode)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 16),
                  child: TextButton(
                    onPressed: _onGetStarted,
                    child: const Text('Skip', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ),
              )
            else
              const SizedBox(height: 24),

            // PageView with depth/scale transition
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = (_pageController.page ?? 0) - index;
                        value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                      }
                      return Transform.scale(
                        scale: Curves.easeOut.transform(value),
                        child: Opacity(
                          opacity: Curves.easeOut.transform(value),
                          child: child,
                        ),
                      );
                    },
                    child: _buildPage(_pages[index], isDark),
                  );
                },
              ),
            ),

            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : (isDark ? AppColors.surfaceHighlight : AppColors.lightSurfaceHighlight),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentPage == _pages.length - 1
                      ? ElevatedButton(
                          key: const ValueKey('action'),
                          onPressed: _onGetStarted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 4,
                            shadowColor: AppColors.primary.withOpacity(0.4),
                          ),
                          child: Text(
                            widget.isHelpMode ? 'Close Manual' : 'Get Started 🚀',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        )
                      : ElevatedButton(
                          key: const ValueKey('next'),
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(color: isDark ? AppColors.surfaceHighlight : AppColors.lightSurfaceHighlight),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
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

  Widget _buildPage(_OnboardingPageData data, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large icon with gradient background
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: data.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.gradientColors.first.withOpacity(0.35),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Icon(data.icon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            data.title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          // Points
          Column(
            children: data.points.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•', style: TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final List<String> points;

  const _OnboardingPageData({
    required this.icon,
    required this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.points,
  });
}
