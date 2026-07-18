import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_stats_provider.dart';
import '../providers/missions_provider.dart';
import '../providers/projects_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/project.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/level_up_celebration.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsNotifierProvider);
    final missionsAsync = ref.watch(missionNotifierProvider);
    final projectsAsync = ref.watch(projectsNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: statsAsync.when(
          data: (stats) {
            final nextLevelTotalXp = LevelSystem.getNextLevelTotalXp(stats.currentLevel);
            final progress = LevelSystem.getLevelProgress(stats.totalXp);
            final currentBaseXp = LevelSystem.getTotalXpForLevel(stats.currentLevel);
            final xpInLevel = stats.totalXp - currentBaseXp;
            final xpNeeded = nextLevelTotalXp - currentBaseXp;

            // Count missions
            final missions = missionsAsync.valueOrNull ?? [];
            final completedToday = missions.where((m) => m.isCompleted).length;
            final totalMissions = missions.length;

            // Weekly activity (last 7 days)
            final now = DateTime.now();
            final weekActivity = List.generate(7, (i) {
              final day = now.subtract(Duration(days: 6 - i));
              return missions.any((m) => m.isCompleted && m.date.year == day.year && m.date.month == day.month && m.date.day == day.day);
            });

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Progress & XP',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getMotivationalTagline(stats.currentLevel, stats.currentStreak),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                              ),
                            ],
                          ),
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
                              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Animated Level Circle
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3 * _pulseAnimation.value),
                                blurRadius: 24 + (12 * _pulseAnimation.value),
                                spreadRadius: 4 + (4 * _pulseAnimation.value),
                              )
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('LVL', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2)),
                                Text(
                                  '${stats.currentLevel}',
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white, fontSize: 52),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // XP Progress
                  Text('CURRENT PROGRESS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$xpInLevel / $xpNeeded XP', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Lvl ${stats.currentLevel + 1} →', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          color: AppColors.primary,
                          minHeight: 12,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Mission Stats
                  Text('TODAY\'S MISSIONS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(context, 'Completed', '$completedToday', Icons.check_circle_rounded, AppColors.success)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatCard(context, 'Total', '$totalMissions', Icons.list_alt_rounded, AppColors.secondary)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Streaks
                  Text('STREAKS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(context, 'Current Streak', '${stats.currentStreak} Days', Icons.local_fire_department_rounded, AppColors.accent)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatCard(context, 'Longest Streak', '${stats.longestStreak} Days', Icons.emoji_events_rounded, AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Weekly Activity
                  Text('WEEKLY ACTIVITY', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  _buildWeeklyActivity(context, weekActivity),
                  const SizedBox(height: 20),

                  // Badges
                  Text('BADGES', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  _buildBadgesSection(context, stats.currentLevel, stats.currentStreak, stats.longestStreak),
                  const SizedBox(height: 28),

                  // Active Projects (moved from Profile)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ACTIVE PROJECTS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
                      InkWell(
                        onTap: () => _showAddOrEditProjectSheet(context, ref, null),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('Add Project', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  projectsAsync.when(
                    data: (projects) {
                      if (projects.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.folder_open_rounded, size: 38, color: Theme.of(context).textTheme.bodySmall?.color),
                                const SizedBox(height: 10),
                                Text('No active projects yet', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Tap "+ Add Project" above to start tracking.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: projects.map((p) => _buildProjectCard(context, ref, p)).toList(),
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  String _getMotivationalTagline(int level, int streak) {
    if (streak >= 14) return 'Unstoppable! You\'re a force of nature! 🌪️';
    if (streak >= 7) return 'One week strong! Keep the fire alive! 🔥';
    if (streak >= 3) return 'Building momentum! Don\'t stop now! 💪';
    if (level >= 10) return 'You\'re becoming a legend! 🏆';
    if (level >= 5) return 'Solid progress! You\'re leveling up fast! ⚡';
    if (level >= 2) return 'Great start! Every XP counts! 🌱';
    return 'Track your sustained meaningful growth. ✨';
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivity(BuildContext context, List<bool> weekActivity) {
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final day = now.subtract(Duration(days: 6 - i));
          final isActive = weekActivity[i];
          final isToday = i == 6;

          return Column(
            children: [
              Text(
                dayLabels[day.weekday - 1],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? AppColors.primary : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.success.withOpacity(0.85)
                      : (isToday ? AppColors.primary.withOpacity(0.15) : Colors.transparent),
                  border: Border.all(
                    color: isActive
                        ? AppColors.success
                        : (isToday ? AppColors.primary.withOpacity(0.5) : Theme.of(context).colorScheme.surfaceContainerHighest),
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: isActive
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Badge System (data from level_up_celebration.dart) ──

  Widget _buildBadgesSection(BuildContext context, int currentLevel, int currentStreak, int longestStreak) {
    // Show unlocked badges first, then locked
    final unlocked = allBadges.where((b) => currentLevel >= b.level).toList();
    final locked = allBadges.where((b) => currentLevel < b.level).toList();

    final unlockedCount = unlocked.length;
    final totalCount = allBadges.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.12), AppColors.accent.withOpacity(0.08)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 22),
              const SizedBox(width: 10),
              Text(
                '$unlockedCount / $totalCount Badges Unlocked',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (locked.isNotEmpty)
                Text(
                  'Next: Lvl ${locked.first.level}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Scrollable badge row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < allBadges.length; i++) ...[
                _buildBadge(context, allBadges[i], currentLevel >= allBadges[i].level),
                if (i < allBadges.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, BadgeData badge, bool isUnlocked) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUnlocked
                ? '${badge.emoji} ${badge.name} — ${badge.desc}'
                : '🔒 ${badge.name} — Reach Lvl ${badge.level} to unlock'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isUnlocked
              ? AppColors.primary.withOpacity(0.1)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnlocked ? AppColors.primary.withOpacity(0.3) : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          boxShadow: isUnlocked
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 10)]
              : [],
        ),
        child: Column(
          children: [
            Text(badge.emoji, style: TextStyle(fontSize: isUnlocked ? 26 : 20)),
            const SizedBox(height: 4),
            Text(badge.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isUnlocked ? null : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.45),
              fontSize: 9,
              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
            )),
            const SizedBox(height: 2),
            Text('Lvl ${badge.level}', style: TextStyle(
              fontSize: 8,
              color: isUnlocked ? AppColors.primary : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.3),
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  // ── Project Cards & Sheets (moved from profile_screen.dart) ──

  Widget _buildProjectCard(BuildContext context, WidgetRef ref, Project project) {
    final percent = (project.progress * 100).toInt();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (project.description != null && project.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(project.description!, style: Theme.of(context).textTheme.bodySmall),
                    ]
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$percent%', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () => _showAddOrEditProjectSheet(context, ref, project),
                    icon: Icon(Icons.edit_outlined, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 10, right: 4),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteProjectConfirm(context, ref, project),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 4),
                  ),
                ],
              ),
            ],
          ),
          if (project.notes != null && project.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Note: ${project.notes!}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Slide to update:', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11)),
              Text(
                percent == 100 ? 'Completed 🎉' : (percent == 0 ? 'Not Started' : 'In Progress'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: percent == 100 ? AppColors.success : AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: percent == 100 ? AppColors.success : AppColors.primary,
              inactiveTrackColor: Theme.of(context).scaffoldBackgroundColor,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: project.progress.clamp(0.0, 1.0),
              onChanged: (val) {
                project.progress = val;
                ref.read(projectsNotifierProvider.notifier).updateProject(project);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditProjectSheet(BuildContext context, WidgetRef ref, Project? existing) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    double progressVal = existing?.progress ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 24, right: 24, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(existing == null ? 'Add Project' : 'Edit Project', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: titleController, decoration: _inputDecoration('Project Title', Icons.folder_rounded)),
                    const SizedBox(height: 14),
                    TextField(controller: descController, decoration: _inputDecoration('Description / Goal', Icons.description_outlined)),
                    const SizedBox(height: 14),
                    TextField(controller: notesController, maxLines: 2, decoration: _inputDecoration('Current Notes', Icons.note_alt_outlined)),
                    const SizedBox(height: 18),
                    Text('Progress: ${(progressVal * 100).toInt()}%', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Slider(value: progressVal, activeColor: AppColors.primary, onChanged: (v) => setState(() => progressVal = v)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          if (existing == null) {
                            ref.read(projectsNotifierProvider.notifier).addProject(
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              progress: progressVal,
                              notes: notesController.text.trim(),
                            );
                          } else {
                            existing.title = titleController.text.trim();
                            existing.description = descController.text.trim();
                            existing.notes = notesController.text.trim();
                            existing.progress = progressVal;
                            ref.read(projectsNotifierProvider.notifier).updateProject(existing);
                          }
                          Navigator.pop(ctx);
                        },
                        child: Text(existing == null ? 'Create Project' : 'Save Changes', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteProjectConfirm(BuildContext context, WidgetRef ref, Project project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Project?'),
        content: Text('Remove "${project.title}" from active projects?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(projectsNotifierProvider.notifier).deleteProject(project.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}
