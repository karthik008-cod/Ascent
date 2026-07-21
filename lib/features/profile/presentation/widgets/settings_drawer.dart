import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../../../tasks/presentation/providers/missions_provider.dart';
import '../../../progress/presentation/providers/user_stats_provider.dart';
import '../../../tasks/presentation/providers/data_providers.dart';
import '../../../journey/presentation/screens/onboarding_screen.dart';

class SettingsDrawer {
  static void show(BuildContext context, WidgetRef ref) {
    final user = ref.read(authNotifierProvider).valueOrNull;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final currentTheme = ref.watch(themeNotifierProvider);
            final isCurrentlyDark = currentTheme == ThemeMode.dark;

            return Container(
              decoration: BoxDecoration(
                color: isCurrentlyDark ? AppColors.surface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isCurrentlyDark ? AppColors.surfaceHighlight : AppColors.lightSurfaceHighlight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // App Header
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withOpacity(0.6), width: 1.5),
                            ),
                            child: ClipOval(
                              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ascent',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isCurrentlyDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              Text(
                                'v1.0.0  •  ${user?.name ?? 'User'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCurrentlyDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Theme Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isCurrentlyDark ? AppColors.background : AppColors.lightBackground,
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrentlyDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            // Creative animated toggle switch
                            GestureDetector(
                              onTap: () {
                                ref.read(themeNotifierProvider.notifier).toggleTheme();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                width: 56,
                                height: 30,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: isCurrentlyDark
                                      ? const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)])
                                      : const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFFBBF24)]),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                  alignment: isCurrentlyDark ? Alignment.centerLeft : Alignment.centerRight,
                                  child: Container(
                                    width: 24,
                                    height: 24,
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
                      const SizedBox(height: 12),

                      // Help / Manual
                      _buildDrawerItem(
                        context: ctx,
                        icon: Icons.menu_book_rounded,
                        label: 'Help & Manual',
                        subtitle: 'Revisit the app walkthrough',
                        color: AppColors.secondary,
                        isDark: isCurrentlyDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OnboardingScreen(isHelpMode: true),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      // Backup to Cloud
                      _buildDrawerItem(
                        context: ctx,
                        icon: Icons.cloud_sync_rounded,
                        label: 'Backup to Cloud',
                        subtitle: 'Sync missions, XP & projects',
                        color: AppColors.primary,
                        isDark: isCurrentlyDark,
                        onTap: () async {
                          Navigator.pop(ctx);
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
                      const SizedBox(height: 8),

                      // Sign Out
                      _buildDrawerItem(
                        context: ctx,
                        icon: Icons.logout_rounded,
                        label: 'Sign Out',
                        subtitle: 'Log out of your account',
                        color: AppColors.error,
                        isDark: isCurrentlyDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          ref.read(authNotifierProvider.notifier).signOut();
                        },
                      ),
                      const SizedBox(height: 8),
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

  static Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color == AppColors.error ? color : (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
