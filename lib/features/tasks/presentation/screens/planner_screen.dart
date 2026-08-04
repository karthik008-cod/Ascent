import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/missions_provider.dart';
import '../providers/projects_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/mission.dart';
import 'package:go_router/go_router.dart';
import '../screens/add_mission_screen.dart';
import '../widgets/filter_sort_bar.dart';
import '../../../profile/presentation/screens/settings_screen.dart';
import '../../../progress/presentation/widgets/level_up_celebration.dart';
import '../../../progress/presentation/providers/user_stats_provider.dart';
import '../../../../core/widgets/climbing_dots_loader.dart';
import '../../../../core/widgets/character_empty_box.dart';
import '../../../../core/widgets/scroll_bender.dart';
import '../../../../core/widgets/swipeable_mission_card.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext screenContext, WidgetRef ref) {
    final isDark = Theme.of(screenContext).brightness == Brightness.dark;
    final missionsAsync = ref.watch(filteredSortedMissionsProvider);

    Future<void> _onRefresh() async {
      ref.invalidate(missionNotifierProvider);
      ref.invalidate(userStatsNotifierProvider);
      ref.invalidate(projectsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Planner & Inbox',
                        style: Theme.of(screenContext).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Intelligently rotate priorities by day.',
                        style: Theme.of(screenContext).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(screenContext).push(PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 600),
                        reverseTransitionDuration: const Duration(milliseconds: 500),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return FadeTransition(
                            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                            child: const SettingsScreen(),
                          );
                        },
                      ));
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.6), width: 1.5),
                      ),
                      child: ClipOval(
                        child: Hero(
                          tag: 'logo_hero',
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter & Sort Bar
            const FilterSortBar(),
            const SizedBox(height: 10),

            missionsAsync.when(
              data: (rawMissions) {
                // Pre-filter missions to remove completed 'Once' tasks
                final missions = rawMissions.where((m) {
                  bool isOnce = m.description == null || (!m.description!.contains('Repeats: Daily') && !m.description!.contains('Repeats: Weekly'));
                  return !(m.isCompleted && isOnce);
                }).toList();

                if (missions.isEmpty) {
                  return Expanded(
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: AppColors.primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(screenContext).size.height * 0.15),
                          const Center(
                            child: CharacterEmptyBox(text: 'No tasks right now.'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final onceMissions = missions.where((m) => _getRepeatMode(m) == 'Once').toList();
                final dailyMissions = missions.where((m) => _getRepeatMode(m) == 'Daily').toList();
                final weeklyMissions = missions.where((m) => _getRepeatMode(m) == 'Weekly').toList();

                final mapOfDays = <String, List<Mission>>{
                  'Monday': [], 'Tuesday': [], 'Wednesday': [], 'Thursday': [],
                  'Friday': [], 'Saturday': [], 'Sunday': [],
                };

                for (final m in weeklyMissions) {
                  final days = _getWeeklyDays(m);
                  for (final d in days) {
                    if (mapOfDays.containsKey(d)) mapOfDays[d]!.add(m);
                  }
                }

                return Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: AppColors.primary,
                    child: ScrollVelocityTracker(
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        children: [
                          if (onceMissions.isNotEmpty) ...[
                            Theme(
                              data: Theme.of(screenContext).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                initiallyExpanded: true,
                                tilePadding: EdgeInsets.zero,
                                title: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _buildSectionBanner(screenContext, icon: '🎯', title: 'ONCE', color: AppColors.accent),
                                ),
                                children: [
                                  for (final m in onceMissions) _buildPlannerTile(screenContext, ref, m, category: 'once'),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                          if (dailyMissions.isNotEmpty) ...[
                            Theme(
                              data: Theme.of(screenContext).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                initiallyExpanded: true,
                                tilePadding: EdgeInsets.zero,
                                title: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _buildSectionBanner(screenContext, icon: '🔁', title: 'DAILY', color: AppColors.primary),
                                ),
                                children: [
                                  for (final m in dailyMissions) _buildPlannerTile(screenContext, ref, m, category: 'daily'),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                          ...['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map((day) {
                            final dayTasks = mapOfDays[day]!;
                            if (dayTasks.isEmpty) return const SizedBox.shrink();
                            
                            final dayMap = {'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4, 'Friday': 5, 'Saturday': 6, 'Sunday': 7};
                            final dayIndex = dayMap[day]!;
                            
                            return Theme(
                              data: Theme.of(screenContext).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                initiallyExpanded: true,
                                tilePadding: EdgeInsets.zero,
                                title: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _buildSectionBanner(screenContext, icon: null, title: day.toUpperCase(), color: AppColors.success),
                                ),
                                children: [
                                  for (final m in dayTasks) _buildPlannerTile(screenContext, ref, m, category: day, dayIndex: dayIndex),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Expanded(child: Center(child: ClimbingDotsLoader())),
              error: (e, st) => Expanded(child: Center(child: Text('Error: $e'))),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          screenContext.push('/add-task');
        },
        backgroundColor: AppColors.secondary,
        tooltip: 'Add Mission / Task',
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }


  Widget _buildPlannerTile(BuildContext context, WidgetRef ref, Mission mission, {String category = '', int? dayIndex}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    bool isCompleted = mission.isCompleted;
    if (dayIndex != null) {
       isCompleted = isMissionCompletedForDay(mission, dayIndex);
    }
    
    Future<bool> showCompleteConfirmation() async {
      return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              const SizedBox(width: 10),
              Text('Delete Permanently?', style: Theme.of(ctx).textTheme.titleLarge),
            ],
          ),
          content: Text(
            'Marking a task as complete from the Planner tab will delete it permanently from the app, and it will never repeat again.\n\nAre you sure you want to proceed?',
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ) ?? false;
    }

    Future<bool> showDeleteConfirmation() async {
      return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.delete_forever_rounded, color: AppColors.error),
              const SizedBox(width: 10),
              Text('Delete Task?', style: Theme.of(ctx).textTheme.titleLarge),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete this task?\nThis action cannot be undone.',
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ) ?? false;
    }

    return ScrollBender(
      child: SwipeableMissionCard(
        key: ValueKey('planner_${mission.id}_$category'),
        mission: mission,
        confirmComplete: showCompleteConfirmation,
        confirmDelete: showDeleteConfirmation,
        onComplete: () async {
          final event = await ref.read(missionNotifierProvider.notifier).toggleMissionStatus(mission, fromPlanner: true, plannerDayIndex: dayIndex);
          if (event != null && context.mounted) {
            showLevelUpCelebration(context, event.oldLevel, event.newLevel);
          }
        },
        onDelete: () async {
          await ref.read(missionNotifierProvider.notifier).deleteMission(mission.id);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppColors.surface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.push('/add-task', extra: mission);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    bool confirm = await showCompleteConfirmation();
                    if (!confirm) return;

                    final event = await ref.read(missionNotifierProvider.notifier).toggleMissionStatus(mission, fromPlanner: true, plannerDayIndex: dayIndex);
                    if (event != null && context.mounted) {
                      showLevelUpCelebration(context, event.oldLevel, event.newLevel);
                    }
                  },
                  child: Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: isCompleted ? AppColors.success : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              mission.title,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted ? (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary) : (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTypeColor(mission.type).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${mission.xpReward} XP',
                              style: TextStyle(color: _getTypeColor(mission.type), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary).withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(mission.date),
                            style: TextStyle(fontSize: 12, color: (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary).withOpacity(0.8)),
                          ),
                          if (mission.description != null && mission.description!.contains('Reminder:')) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.alarm_rounded, size: 13, color: AppColors.primary.withOpacity(0.9)),
                            const SizedBox(width: 4),
                            Text(
                              _extractReminder(mission.description!),
                              style: TextStyle(fontSize: 12, color: AppColors.primary.withOpacity(0.9)),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit_outlined, size: 16, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
              ],
            ),
          ),
        ),
      ),
     ),
    ),
   );
  }

  Color _getTypeColor(MissionType type) {
    switch (type) {
      case MissionType.main:
        return AppColors.accent;
      case MissionType.side:
        return AppColors.primary;
      case MissionType.routine:
        return AppColors.success;
    }
  }

  String _extractReminder(String desc) {
    final lines = desc.split('\n');
    for (final line in lines) {
      if (line.startsWith('Reminder: ')) {
        return line.substring(10);
      }
    }
    return '';
  }

  String _getRepeatMode(Mission m) {
    if (m.description == null) return 'Once';
    if (m.description!.contains('Repeats: Daily')) return 'Daily';
    if (m.description!.contains('Repeats: Weekly')) return 'Weekly';
    return 'Once';
  }

  List<String> _getWeeklyDays(Mission m) {
    final desc = m.description;
    if (desc == null || !desc.contains('Repeats: Weekly')) return [];
    
    final match = RegExp(r'Days:\s*([0-9a-zA-Z,\s]+)').firstMatch(desc);
    if (match != null && match.group(1) != null) {
      final days = <String>[];
      final reverseMap = {'Mon': 'Monday', 'Tue': 'Tuesday', 'Wed': 'Wednesday', 'Thu': 'Thursday', 'Fri': 'Friday', 'Sat': 'Saturday', 'Sun': 'Sunday'};
      final numMap = {'1': 'Monday', '2': 'Tuesday', '3': 'Wednesday', '4': 'Thursday', '5': 'Friday', '6': 'Saturday', '7': 'Sunday'};
      
      for (final s in match.group(1)!.split(',')) {
        final val = s.trim();
        if (reverseMap.containsKey(val)) {
          days.add(reverseMap[val]!);
        } else if (numMap.containsKey(val)) {
          days.add(numMap[val]!);
        }
      }
      return days;
    }
    
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return [dayNames[m.date.weekday - 1]];
  }

  Widget _buildSectionBanner(BuildContext context, {String? icon, required String title, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
