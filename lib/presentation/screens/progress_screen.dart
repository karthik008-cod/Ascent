import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_stats_provider.dart';
import '../../core/constants/app_colors.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: statsAsync.when(
          data: (stats) {
            final nextLevelXp = stats.currentLevel * 100;
            final progress = (stats.totalXp % 100) / 100.0;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Progress & XP',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Track your sustained meaningful growth.',
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
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 6,
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
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('CURRENT PROGRESS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${stats.totalXp} XP', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text('$nextLevelXp XP', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceHighlight,
                    color: AppColors.primary,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 36),
                  Text('STATISTICS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(context, 'Current Streak', '${stats.currentStreak} Days', Icons.local_fire_department_rounded, AppColors.accent)),
                      const SizedBox(width: 14),
                      Expanded(child: _buildStatCard(context, 'Longest Streak', '${stats.longestStreak} Days', Icons.emoji_events_rounded, AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('BADGES', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildBadge(context, 'Pioneer', Icons.explore_rounded, true),
                      const SizedBox(width: 14),
                      _buildBadge(context, 'Consistent', Icons.calendar_month_rounded, stats.currentStreak >= 7),
                      const SizedBox(width: 14),
                      _buildBadge(context, 'Achiever', Icons.star_rounded, stats.currentLevel >= 5),
                    ],
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

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 14),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String name, IconData icon, bool isUnlocked) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.surfaceHighlight.withOpacity(0.5) : AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isUnlocked ? AppColors.primary.withOpacity(0.3) : AppColors.surfaceHighlight),
        boxShadow: isUnlocked ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
          )
        ] : [],
      ),
      child: Column(
        children: [
          Icon(icon, color: isUnlocked ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3), size: 30),
          const SizedBox(height: 8),
          Text(name, style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary.withOpacity(0.5),
            fontSize: 11,
          )),
        ],
      ),
    );
  }
}
