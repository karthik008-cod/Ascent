import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/missions_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/mission.dart';
import '../widgets/add_mission_sheet.dart';
import '../widgets/filter_sort_bar.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/level_up_celebration.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final missionsAsync = ref.watch(filteredSortedMissionsProvider);

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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Intelligently rotate priorities by day.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => SettingsDrawer.show(context, ref),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.6), width: 1.5),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
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
              data: (missions) {
                if (missions.isEmpty) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 64, color: isDark ? AppColors.surfaceHighlight : AppColors.lightSurfaceHighlight),
                          const SizedBox(height: 16),
                          Text('No tasks right now.', style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: missions.length,
                    itemBuilder: (context, index) {
                      final mission = missions[index];
                      return _buildPlannerTile(context, ref, mission);
                    },
                  ),
                );
              },
              loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
              error: (e, st) => Expanded(child: Center(child: Text('Error: $e'))),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddMissionSheet(),
          );
        },
        backgroundColor: AppColors.secondary,
        tooltip: 'Add Mission / Task',
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }


  Widget _buildPlannerTile(BuildContext context, WidgetRef ref, Mission mission) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppColors.surface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddMissionSheet(existingMission: mission),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final newLevel = await ref.read(missionNotifierProvider.notifier).toggleMissionStatus(mission);
                    if (newLevel != null && context.mounted) {
                      showLevelUpCelebration(context, newLevel);
                    }
                  },
                  child: Icon(
                    mission.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: mission.isCompleted ? AppColors.success : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
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
                                decoration: mission.isCompleted ? TextDecoration.lineThrough : null,
                                color: mission.isCompleted ? (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary) : (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
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
}
