import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/planner_screen.dart';
import '../../presentation/screens/progress_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/main_scaffold.dart';
import '../../presentation/screens/auth_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/providers/auth_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Tracks whether user has seen onboarding. Loaded once at startup.
final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasSeenOnboarding') ?? false;
});

class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, next) {
      notifyListeners();
    });
    ref.listen(hasSeenOnboardingProvider, (_, next) {
      notifyListeners();
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final onboardingState = ref.read(hasSeenOnboardingProvider);
      
      if (authState.isLoading) return null;

      final hasSeenOnboarding = onboardingState.valueOrNull ?? false;
      final isAuthenticated = authState.valueOrNull != null;
      final currentPath = state.matchedLocation;

      // First: check onboarding
      if (!hasSeenOnboarding && currentPath != '/onboarding') {
        return '/onboarding';
      }

      // Then: check auth
      if (hasSeenOnboarding && !isAuthenticated && currentPath != '/auth' && currentPath != '/onboarding') {
        return '/auth';
      }
      if (isAuthenticated && (currentPath == '/auth' || currentPath == '/onboarding')) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
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
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/planner',
                builder: (context, state) => const PlannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
