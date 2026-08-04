import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tasks/presentation/providers/missions_provider.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key, required this.navigationShell});
  
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _NetworkBannerWrapper(
      child: _ReminderWrapper(
        child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          onDestinationSelected: (int idx) => navigationShell.goBranch(
            idx,
            initialLocation: idx == navigationShell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Today'),
            NavigationDestination(icon: Icon(Icons.calendar_view_week_rounded), label: 'Planner'),
            NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: 'Progress'),
            NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class AnimatedTabContainer extends StatefulWidget {
  const AnimatedTabContainer({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<AnimatedTabContainer> createState() => _AnimatedTabContainerState();
}

class _AnimatedTabContainerState extends State<AnimatedTabContainer> {
  late PageController _pageController;
  bool _isAnimatingProgrammatically = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.navigationShell.currentIndex);
  }

  @override
  void didUpdateWidget(covariant AnimatedTabContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.navigationShell.currentIndex;
    final oldIndex = oldWidget.navigationShell.currentIndex;
    
    if (newIndex != oldIndex) {
      if (_pageController.hasClients && _pageController.page?.round() != newIndex) {
        _isAnimatingProgrammatically = true;
        if ((newIndex - oldIndex).abs() > 1) {
          final jumpIndex = newIndex > oldIndex ? newIndex - 1 : newIndex + 1;
          _pageController.jumpToPage(jumpIndex);
        }
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ).then((_) {
          _isAnimatingProgrammatically = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
      onPageChanged: (index) {
        if (_isAnimatingProgrammatically) return;
        if (index != widget.navigationShell.currentIndex) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        }
      },
      children: widget.children,
    );
  }
}

class _ReminderWrapper extends ConsumerStatefulWidget {
  const _ReminderWrapper({required this.child});
  final Widget child;

  @override
  ConsumerState<_ReminderWrapper> createState() => _ReminderWrapperState();
}

class _ReminderWrapperState extends ConsumerState<_ReminderWrapper> {
  Timer? _reminderTimer;
  final Set<int> _alertedMissionIds = {};

  @override
  void initState() {
    super.initState();
    _startReminderCheck();
  }

  void _startReminderCheck() {
    _reminderTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!mounted) return;
      final missionsAsync = ref.read(missionNotifierProvider);
      missionsAsync.whenData((missions) {
        final now = TimeOfDay.now();
        final nowStr = now.format(context);

        for (final mission in missions) {
          if (!mission.isCompleted && mission.description != null && mission.description!.contains('Reminder: ')) {
            final lines = mission.description!.split('\n');
            for (final line in lines) {
              if (line.startsWith('Reminder: ')) {
                final timeStr = line.substring(10).trim();
                if (timeStr == nowStr && !_alertedMissionIds.contains(mission.id)) {
                  _alertedMissionIds.add(mission.id);
                  _triggerReminderAlert(mission.title, timeStr);
                }
              }
            }
          }
        }
      });
    });
  }

  void _triggerReminderAlert(String title, String timeStr) {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.alarm_on_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('Mission Reminder', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('It\'s $timeStr! Time to focus on your mission:', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Start Now',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _NetworkBannerWrapper extends StatefulWidget {
  final Widget child;
  const _NetworkBannerWrapper({required this.child});

  @override
  State<_NetworkBannerWrapper> createState() => _NetworkBannerWrapperState();
}

class _NetworkBannerWrapperState extends State<_NetworkBannerWrapper> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  bool _showOnlineSuccess = false;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final isNowOffline = results.contains(ConnectivityResult.none) || results.isEmpty;
      if (isNowOffline && !_isOffline) {
        // Just went offline
        setState(() {
          _isOffline = true;
          _showOnlineSuccess = false;
          _bannerDismissed = false;
        });
      } else if (!isNowOffline && _isOffline) {
        // Just came back online
        setState(() {
          _isOffline = false;
          _showOnlineSuccess = true;
        });
        // Hide success banner after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showOnlineSuccess = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showOfflineBanner = _isOffline && !_bannerDismissed;
    final bool showBanner = showOfflineBanner || _showOnlineSuccess;

    return Stack(
      children: [
        widget.child,
        
        // Floating Banner
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutBack,
          top: showBanner ? MediaQuery.of(context).padding.top + 10 : -100,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: showOfflineBanner ? Colors.red.shade600 : Colors.green.shade600,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    showOfflineBanner ? Icons.wifi_off_rounded : Icons.cloud_done_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      showOfflineBanner 
                          ? 'You are offline. Updates will be synced when you are back online.'
                          : 'BACK ONLINE. All your updates have been committed.',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (showOfflineBanner) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _bannerDismissed = true;
                        });
                      },
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
