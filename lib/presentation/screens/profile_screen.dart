import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/data_providers.dart';
import '../providers/missions_provider.dart';
import '../providers/user_stats_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.value;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile & Settings',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage cloud sync and preferences.',
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
            const SizedBox(height: 20),
            const Center(
              child: CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.surfaceHighlight,
                child: Icon(Icons.person, size: 44, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(user?.name ?? 'Yuvaan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            if (user?.email != null)
              Center(
                child: Text(user!.email, style: Theme.of(context).textTheme.bodyMedium),
              ),
            const SizedBox(height: 32),
            Text('ACTIVE PROJECTS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _buildProjectCard(context, 'App Development', 0.65),
            _buildProjectCard(context, 'Operating Systems', 0.30),
            const SizedBox(height: 28),
            Text('SETTINGS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceHighlight),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_rounded, color: AppColors.primary),
                    title: const Text('Backup Data to Cloud'),
                    subtitle: const Text('Sync missions & XP to MongoDB'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please log in to backup data.')),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Starting backup to MongoDB...')),
                      );
                      try {
                        final missions = ref.read(missionNotifierProvider).value ?? [];
                        final stats = ref.read(userStatsNotifierProvider).value;
                        if (stats != null) {
                          final mongo = ref.read(mongoDataSourceProvider);
                          await mongo.backupData(user.id, missions, stats);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Successfully synced to cloud!')),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Backup Failed: $e')),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(color: AppColors.surfaceHighlight, height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                    title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.error),
                    onTap: () {
                      ref.read(authNotifierProvider.notifier).signOut();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, String title, double progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toInt()}%', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.background,
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      ),
    );
  }
}
