import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/project.dart';
import '../providers/auth_provider.dart';
import '../providers/data_providers.dart';
import '../providers/missions_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/user_stats_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.value ?? AuthUser(id: 'local_user', email: 'yuvaan@ascent.app', name: 'Yuvaan');
    final projectsAsync = ref.watch(projectsNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile & Projects',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customize your identity and active endeavors.',
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
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 1.5),
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

            // Profile Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surfaceHighlight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'Y',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${user.role}  •  ${user.socialHandle}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showEditProfileSheet(context, ref, user),
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                        tooltip: 'Edit Profile Details',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceHighlight.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.format_quote_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              user.motto,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.bio,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Active Projects Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACTIVE PROJECTS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.textSecondary),
                ),
                InkWell(
                  onTap: () => _showAddOrEditProjectSheet(context, ref, null),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Add Project',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Active Projects List
            projectsAsync.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.surfaceHighlight),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.folder_open_rounded, size: 38, color: AppColors.textSecondary),
                          const SizedBox(height: 10),
                          Text(
                            'No active projects yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "+ Add Project" above to start tracking real endeavors.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: projects.map((project) => _buildInteractiveProjectCard(context, ref, project)).toList(),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
              error: (e, st) => Center(child: Text('Error loading projects: $e')),
            ),
            const SizedBox(height: 28),

            // Settings Header
            Text(
              'SETTINGS & CLOUD SYNC',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.textSecondary),
            ),
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
                    subtitle: const Text('Sync missions, XP & projects to MongoDB'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
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
                              const SnackBar(content: Text('Successfully synced all data to cloud!')),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Backup Status: Saved locally ($e)')),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(color: AppColors.surfaceHighlight, height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                    title: const Text('Reset Guest Session / Sign Out', style: TextStyle(color: AppColors.error)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.error),
                    onTap: () {
                      ref.read(authNotifierProvider.notifier).signOut();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveProjectCard(BuildContext context, WidgetRef ref, Project project) {
    final percent = (project.progress * 100).toInt();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (project.description != null && project.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        project.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
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
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$percent%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showAddOrEditProjectSheet(context, ref, project),
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 10, right: 4),
                    tooltip: 'Edit Project',
                  ),
                  IconButton(
                    onPressed: () => _showDeleteProjectConfirm(context, ref, project),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 4),
                    tooltip: 'Delete Project',
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
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Note: ${project.notes!}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Interactive Real-time Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Slide to update progress:',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
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
                  inactiveTrackColor: AppColors.background,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: project.progress.clamp(0.0, 1.0),
                  onChanged: (val) {
                    // Update state directly for smooth UI flexibility
                    project.progress = val;
                    ref.read(projectsNotifierProvider.notifier).updateProject(project);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, AuthUser user) {
    final nameController = TextEditingController(text: user.name);
    final roleController = TextEditingController(text: user.role);
    final socialController = TextEditingController(text: user.socialHandle);
    final mottoController = TextEditingController(text: user.motto);
    final bioController = TextEditingController(text: user.bio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Profile & Bio', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: _inputDecoration('Display Name', Icons.person_outline),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: roleController,
                  decoration: _inputDecoration('Title / Role (e.g. Lead Pioneer)', Icons.work_outline),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: socialController,
                  decoration: _inputDecoration('Social Handle (e.g. @yuvaan_dev)', Icons.alternate_email_rounded),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: mottoController,
                  decoration: _inputDecoration('Motto / Quote', Icons.format_quote_rounded),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  decoration: _inputDecoration('Bio / About You', Icons.info_outline_rounded),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(authNotifierProvider.notifier).updateProfile(
                        name: nameController.text.trim(),
                        role: roleController.text.trim(),
                        socialHandle: socialController.text.trim(),
                        motto: mottoController.text.trim(),
                        bio: bioController.text.trim(),
                      );
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Profile Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(existing == null ? 'Add Active Project' : 'Edit Project', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: _inputDecoration('Project Title', Icons.folder_rounded),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descController,
                      decoration: _inputDecoration('Description / Goal', Icons.description_outlined),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: _inputDecoration('Current Notes / Next Steps', Icons.note_alt_outlined),
                    ),
                    const SizedBox(height: 18),
                    Text('Initial / Current Progress: ${(progressVal * 100).toInt()}%', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Slider(
                      value: progressVal,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => progressVal = v),
                    ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Project?'),
        content: Text('Are you sure you want to remove "${project.title}" from your active projects?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
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
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }
}
