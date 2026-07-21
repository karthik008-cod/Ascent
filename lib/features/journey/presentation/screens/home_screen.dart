import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../tasks/presentation/providers/missions_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/presentation/widgets/add_mission_sheet.dart';
import '../../../tasks/presentation/widgets/filter_sort_bar.dart';
import '../../../profile/presentation/widgets/settings_drawer.dart';
import '../../../progress/presentation/widgets/level_up_celebration.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final missionsAsync = ref.watch(todayMissionsProvider);
    final currentFilter = ref.watch(missionFilterProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Compact, Time-Aware Top Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDynamicGreeting(ref.watch(authNotifierProvider).value?.name ?? 'Guest'),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'What deserves most of your attention today?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.surfaceHighlight : AppColors.lightSurfaceHighlight).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppColors.surfaceHighlight : AppColors.lightSurfaceHighlight),
                        ),
                        child: Text(
                          DateFormat('E, MMM dd').format(DateTime.now()),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                ],
              ),
            ),

            // Compact Filter & Sort Bar
            const FilterSortBar(),
            const SizedBox(height: 6),

            // Main Priority Mission Board List
            Expanded(
              child: missionsAsync.when(
                data: (missions) {
                  final mainMissions = missions.where((m) => m.type == MissionType.main).toList();
                  final sideMissions = missions.where((m) => m.type == MissionType.side).toList();
                  final routines = missions.where((m) => m.type == MissionType.routine).toList();

                  if (missions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.track_changes_rounded, size: 64, color: isDark ? AppColors.surfaceHighlight : AppColors.lightSurfaceHighlight),
                          const SizedBox(height: 16),
                          Text('No missions assigned for today\'s priority.', style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    children: [
                      if (mainMissions.isEmpty && sideMissions.isEmpty && routines.isEmpty && currentFilter != 'All') ...[
                        const SizedBox(height: 40),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surface : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? AppColors.surfaceHighlight : AppColors.lightSurfaceHighlight),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.filter_list_off_rounded, size: 48, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                                const SizedBox(height: 14),
                                Text(
                                  'No missions found for "$currentFilter"',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Try changing or resetting your filter from the top bar.',
                                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // 🔥 MAIN GOAL (60-70% Effort)
                      if (mainMissions.isNotEmpty || currentFilter == 'Main' || currentFilter == 'All') ...[
                        _buildSectionBanner(
                          context,
                          icon: '🔥',
                          title: 'MAIN GOAL',
                          subtitle: '≈ 60–70% of today\'s focus',
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 10),
                        for (final m in mainMissions) ...[
                          _buildMainGoalCard(context, ref, m),
                          const SizedBox(height: 14),
                        ],
                        if (mainMissions.isEmpty)
                          _buildEmptyGoalBox(context, 'No Main Goal set for today. Focus on high impact!'),
                        const SizedBox(height: 20),
                      ],

                      // ⭐ SIDE GOAL (20-30% Effort)
                      if (sideMissions.isNotEmpty || currentFilter == 'Side' || currentFilter == 'All') ...[
                        _buildSectionBanner(
                          context,
                          icon: '⭐',
                          title: 'SIDE GOAL',
                          subtitle: '≈ 20–30% of today\'s focus',
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 10),
                        for (final m in sideMissions) ...[
                          _buildSideGoalCard(context, ref, m),
                          const SizedBox(height: 12),
                        ],
                        if (sideMissions.isEmpty)
                          _buildEmptyGoalBox(context, 'No Side Goal set. Great for balanced progress!'),
                        const SizedBox(height: 20),
                      ],

                      // ✅ DAILY ROUTINE (10-20% Effort)
                      if (routines.isNotEmpty || currentFilter == 'Routine' || currentFilter == 'All') ...[
                        _buildSectionBanner(
                          context,
                          icon: '✅',
                          title: 'DAILY ROUTINE',
                          subtitle: '≈ 10–20% of today\'s focus',
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 10),
                        for (final m in routines) ...[
                          _buildRoutineTile(context, ref, m),
                        ],
                        if (routines.isEmpty)
                          _buildEmptyGoalBox(context, 'No routines set for consistent daily wins!'),
                        const SizedBox(height: 32),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
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
        backgroundColor: AppColors.primary,
        tooltip: 'Assign Mission Priority',
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  String _getDynamicGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning, $name';
    } else if (hour < 17) {
      return 'Good Afternoon, $name';
    } else {
      return 'Good Evening, $name';
    }
  }


  Widget _buildSectionBanner(BuildContext context, {required String icon, required String title, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: color.withOpacity(0.85),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainGoalCard(BuildContext context, WidgetRef ref, Mission mission) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddMissionSheet(existingMission: mission),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: mission.isCompleted 
              ? const LinearGradient(colors: [AppColors.success, Color(0xFF047857)])
              : AppColors.primaryGradient,
          boxShadow: [
            if (!mission.isCompleted)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('+${mission.xpReward} XP  • Deep Work', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Row(
                  children: [
                    const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        final newLevel = await ref.read(missionNotifierProvider.notifier).toggleMissionStatus(mission);
                        if (newLevel != null && context.mounted) {
                          showLevelUpCelebration(context, newLevel);
                        }
                      },
                      child: mission.isCompleted
                          ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 30)
                          : const Icon(Icons.circle_outlined, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              mission.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (mission.description != null && mission.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                mission.description!.split('\n').first,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.85), fontSize: 13),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSideGoalCard(BuildContext context, WidgetRef ref, Mission mission) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddMissionSheet(existingMission: mission),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: mission.isCompleted ? AppColors.success.withOpacity(0.4) : AppColors.primary.withOpacity(0.35), width: 1.2),
        ),
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
                color: mission.isCompleted ? AppColors.success : AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      decoration: mission.isCompleted ? TextDecoration.lineThrough : null,
                      color: mission.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (mission.description != null && mission.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      mission.description!.split('\n').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('+${mission.xpReward} XP', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineTile(BuildContext context, WidgetRef ref, Mission mission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddMissionSheet(existingMission: mission),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                    color: mission.isCompleted ? AppColors.success : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    mission.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: mission.isCompleted ? TextDecoration.lineThrough : null,
                      color: mission.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text('+${mission.xpReward} XP', style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyGoalBox(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceHighlight.withOpacity(0.4), style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
