import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/journey/presentation/screens/home_screen.dart';
import '../../features/tasks/presentation/screens/planner_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/journey/presentation/screens/main_scaffold.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/journey/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/tasks/presentation/screens/add_mission_screen.dart';
import '../../features/journey/presentation/screens/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final splashNotifierProvider = StateProvider<bool>((ref) => false);

class OnboardingNotifier extends StateNotifier<AsyncValue<bool>> {
  OnboardingNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    state = AsyncValue.data(prefs.getBool('hasSeenOnboarding') ?? false);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    state = const AsyncValue.data(true);
  }
}

final onboardingNotifierProvider = StateNotifierProvider<OnboardingNotifier, AsyncValue<bool>>((ref) {
  return OnboardingNotifier();
});

class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, next) {
      notifyListeners();
    });
    ref.listen(onboardingNotifierProvider, (_, next) {
      notifyListeners();
    });
  }
}

Page<dynamic> _buildPageWithDefaultTransition<T>({
  required BuildContext context, 
  required GoRouterState state, 
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 600),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeIn,
            ),
          ),
          child: child,
        ),
      );
    },
  );
}

Page<dynamic> _buildPageWithTurnTransition<T>({
  required BuildContext context, 
  required GoRouterState state, 
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 600),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Bottom-up vertical scroll/unroll animation
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.6),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      final rotateAnimation = Tween<double>(
        begin: -0.15,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ));

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(rotateAnimation.value),
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final onboardingState = ref.read(onboardingNotifierProvider);
      final hasShownSplash = ref.read(splashNotifierProvider);
      final currentPath = state.uri.path;

      if (!hasShownSplash) {
        if (currentPath != '/splash') return '/splash';
        return null;
      }
      
      if (authState.isLoading || onboardingState.isLoading) {
        if (currentPath != '/splash') return '/splash';
        return null;
      }

      final hasSeenOnboarding = onboardingState.value ?? false;
      final isAuthenticated = authState.valueOrNull != null;

      if (!hasSeenOnboarding) {
        if (currentPath != '/onboarding') {
          return '/onboarding';
        }
        return null;
      }

      if (!isAuthenticated) {
        if (currentPath != '/auth') {
          return '/auth';
        }
        return null;
      }

      if (currentPath == '/auth' || currentPath == '/onboarding' || currentPath == '/splash') {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _buildPageWithDefaultTransition(
          context: context, state: state, child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _buildPageWithDefaultTransition(
          context: context, state: state, child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => _buildPageWithDefaultTransition(
          context: context, state: state, child: const AuthScreen(),
        ),
      ),
      GoRoute(
        path: '/add-task',
        pageBuilder: (context, state) {
          final extra = state.extra;
          return _buildPageWithTurnTransition(
            context: context,
            state: state,
            child: AddMissionScreen(
              existingMission: extra != null ? extra as dynamic : null,
            ),
          );
        },
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return AnimatedTabContainer(
            navigationShell: navigationShell,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                  context: context, state: state, child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/planner',
                pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                  context: context, state: state, child: const PlannerScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                  context: context, state: state, child: const ProgressScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                  context: context, state: state, child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
