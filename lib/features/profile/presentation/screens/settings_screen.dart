import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../../../tasks/presentation/providers/missions_provider.dart';
import '../../../progress/presentation/providers/user_stats_provider.dart';
import '../../../tasks/presentation/providers/data_providers.dart';
import '../../../journey/presentation/screens/onboarding_screen.dart';
import '../../../../core/widgets/dynamic_loading_indicator.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Fade in settings content after Hero animation completes (approx 300ms)
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeNotifierProvider);
    final isCurrentlyDark = currentTheme == ThemeMode.dark;
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      backgroundColor: isCurrentlyDark ? AppColors.background : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.width, // Fills width
            backgroundColor: isCurrentlyDark ? AppColors.surface : AppColors.lightSurface,
            automaticallyImplyLeading: false, // We'll add custom back button
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'logo_hero',
                    child: Container(
                      color: isCurrentlyDark ? AppColors.surface : AppColors.lightSurface,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Custom Back Button over the Hero
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 20,
                    child: AnimatedOpacity(
                      opacity: _opacity,
                      duration: const Duration(milliseconds: 400),
                      child: GestureDetector(
                        onTap: () {
                          // Fade out first, then pop to reverse Hero
                          setState(() {
                            _opacity = 0.0;
                          });
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if (mounted) Navigator.pop(context);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings & Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isCurrentlyDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v1.0.0  •  ${user?.name ?? 'User'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isCurrentlyDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Theme Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isCurrentlyDark ? AppColors.surface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isCurrentlyDark ? AppColors.surfaceHighlight : AppColors.lightSurfaceHighlight,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) {
                              return RotationTransition(
                                turns: Tween(begin: 0.5, end: 1.0).animate(animation),
                                child: ScaleTransition(scale: animation, child: child),
                              );
                            },
                            child: Icon(
                              isCurrentlyDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              key: ValueKey(isCurrentlyDark),
                              color: isCurrentlyDark ? AppColors.accent : const Color(0xFFF59E0B),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              isCurrentlyDark ? 'Dark Mode' : 'Light Mode',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCurrentlyDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ref.read(themeNotifierProvider.notifier).toggleTheme();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              width: 60,
                              height: 32,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: isCurrentlyDark
                                    ? const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)])
                                    : const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFFBBF24)]),
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                alignment: isCurrentlyDark ? Alignment.centerLeft : Alignment.centerRight,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isCurrentlyDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                                    size: 14,
                                    color: isCurrentlyDark ? const Color(0xFF312E81) : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Help / Manual
                    _buildSettingsItem(
                      icon: Icons.menu_book_rounded,
                      label: 'Help & Manual',
                      subtitle: 'Revisit the app walkthrough',
                      color: AppColors.secondary,
                      isDark: isCurrentlyDark,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OnboardingScreen(isHelpMode: true)),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Backup to Cloud
                    _buildSettingsItem(
                      icon: Icons.cloud_sync_rounded,
                      label: 'Backup to Cloud',
                      subtitle: 'Sync missions, XP & projects',
                      color: AppColors.primary,
                      isDark: isCurrentlyDark,
                      onTap: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Starting backup to MongoDB...')),
                        );
                        try {
                          final missions = ref.read(missionNotifierProvider).value ?? [];
                          final stats = ref.read(userStatsNotifierProvider).value;
                          if (stats != null && user != null) {
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
                    const SizedBox(height: 12),

                    // Switch Account
                    _buildSettingsItem(
                      icon: Icons.switch_account_rounded,
                      label: 'Switch Account',
                      subtitle: 'Log into a different account',
                      color: AppColors.secondary,
                      isDark: isCurrentlyDark,
                      onTap: () => _showSwitchAccountSheet(context, ref),
                    ),
                    const SizedBox(height: 12),

                    // Sign Out
                    _buildSettingsItem(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      subtitle: 'Log out of your account',
                      color: AppColors.error,
                      isDark: isCurrentlyDark,
                      onTap: () {
                        ref.read(authNotifierProvider.notifier).signOut();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Delete Account
                    _buildSettingsItem(
                      icon: Icons.person_remove_rounded,
                      label: 'Delete Account',
                      subtitle: 'Permanently remove your data',
                      color: AppColors.error,
                      isDark: isCurrentlyDark,
                      onTap: () => _showDeleteAccountConfirmation(context, ref, isCurrentlyDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppColors.surface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.surfaceHighlight.withOpacity(0.5) : AppColors.lightSurfaceHighlight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color == AppColors.error ? color : (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context, WidgetRef ref, bool isDark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isDeleting = false;
            
            return ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeOutBack,
              )),
              child: FadeTransition(
                opacity: animation,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
                  contentPadding: const EdgeInsets.all(32),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 48),
                      ),
                      const SizedBox(height: 24),
                      Text('Delete Account?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                      const SizedBox(height: 16),
                      if (isDeleting)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: DynamicLoadingIndicator(
                            messages: ['Connecting to server...', 'Erasing cloud data...', 'Wiping local storage...', 'Signing out...'],
                            color: AppColors.error,
                          ),
                        )
                      else ...[
                        Text(
                          'This action is permanent and cannot be undone.\n\nAll your missions, XP, streaks, badges, and projects will be permanently deleted.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            height: 1.5,
                            fontSize: 14,
                            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: isDark ? AppColors.surfaceHighlight : AppColors.lightSurfaceHighlight),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  setState(() => isDeleting = true);
                                  await ref.read(authNotifierProvider.notifier).deleteAccount();
                                  if (context.mounted) {
                                    Navigator.pop(context); // pop dialog
                                    Navigator.pop(context); // pop settings
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSwitchAccountSheet(BuildContext context, WidgetRef ref) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final savedUsers = await authNotifier.getSavedUsers();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final isDark = ref.watch(themeNotifierProvider) == ThemeMode.dark;
            final currentUser = ref.watch(authNotifierProvider).valueOrNull;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceHighlight : AppColors.lightSurfaceHighlight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text('Switch Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                      const SizedBox(height: 16),
                      if (savedUsers.isEmpty)
                        Text('No other accounts saved.', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary))
                      else
                        ...savedUsers.map((user) {
                          final isCurrent = currentUser?.email == user.email;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              child: Text(user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U', style: const TextStyle(color: AppColors.primary)),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name, 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Current account', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(user.email, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                            onTap: isCurrent ? null : () {
                              Navigator.pop(ctx); // pop sheet
                              Navigator.pop(context); // pop settings
                              authNotifier.switchAccount(user);
                            },
                          );
                        }),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.secondary.withOpacity(0.15),
                          child: const Icon(Icons.add_rounded, color: AppColors.secondary),
                        ),
                        title: Text('Add an account', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                          authNotifier.signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
