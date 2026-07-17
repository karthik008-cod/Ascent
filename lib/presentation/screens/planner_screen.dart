import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/missions_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/mission.dart';
import '../widgets/add_mission_sheet.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(filteredSortedMissionsProvider);
    final currentFilter = ref.watch(missionFilterProvider);
    final currentSort = ref.watch(missionSortProvider);

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
                          color: AppColors.textPrimary,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Intelligently rotate priorities by day.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
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
                ],
              ),
            ),

            // Filter & Sort Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(context, ref, 'All', currentFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, ref, 'Main', currentFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, ref, 'Side', currentFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, ref, 'Routine', currentFilter),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceHighlight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentSort,
                          icon: const Icon(Icons.sort_rounded, size: 16, color: AppColors.primary),
                          dropdownColor: AppColors.surface,
                          items: ['Default', 'XP High to Low', 'Title A-Z', 'Incomplete First'].map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(missionSortProvider.notifier).state = val;
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            missionsAsync.when(
              data: (missions) {
                if (missions.isEmpty) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 64, color: AppColors.surfaceHighlight),
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

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, String currentFilter) {
    final isSelected = currentFilter == label;
    return GestureDetector(
      onTap: () {
        ref.read(missionFilterProvider.notifier).state = label;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? AppColors.secondary : AppColors.surfaceHighlight),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPlannerTile(BuildContext context, WidgetRef ref, Mission mission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
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
                  onTap: () {
                    ref.read(missionNotifierProvider.notifier).toggleMissionStatus(mission);
                  },
                  child: Icon(
                    mission.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: mission.isCompleted ? AppColors.success : AppColors.textSecondary,
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
                                color: mission.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
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
                          Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(mission.date),
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.8)),
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
                const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
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
