import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/missions_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key, required this.child});
  
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ReminderWrapper(
      child: Scaffold(
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(context),
          onTap: (int idx) => _onItemTapped(idx, context),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Today'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_view_week_rounded), label: 'Planner'),
            BottomNavigationBarItem(icon: Icon(Icons.show_chart_rounded), label: 'Progress'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/planner')) return 1;
    if (location.startsWith('/progress')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/planner');
        break;
      case 2:
        GoRouter.of(context).go('/progress');
        break;
      case 3:
        GoRouter.of(context).go('/profile');
        break;
    }
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

    NotificationService.showInstantNotification(
      title: 'Ascent Reminder: $title',
      body: 'It is $timeStr! Time to focus on your mission.',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.alarm_on_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 12),
            Text('Mission Reminder'),
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
